library(DBI)
library(knitr)
library(kableExtra)
library(RPostgres)
library(shiny)
library(shinyjs)
library(tidyverse)
library(lubridate)
library(jsonlite)
library(quantr)

options(dplyr.summarise.inform=FALSE)
# Somewhat hacky way to tell if running hosted, but still the recommended method
# https://stackoverflow.com/questions/31423144/how-to-know-if-the-app-is-running-at-local-or-on-server-r-shiny
is_local <- Sys.getenv('SHINY_PORT') == ""

if (is_local) {
    creds_fn <- 'creds.json'
} else {
    creds_fn <- "/mnt/shiny/quant_us/creds.json"
}

MEASURANDS <- c("NO2", "O3", "PM2.5")
MET_FIELDS <- c('Temperature', 'RelHumidity')
STUDY_START <- as_date("2019-12-10")
STUDY_END <- as_date("2022-10-31")
CREDS <- fromJSON(creds_fn)
MAX_COMPARISONS <- 4

download_data <- function(con, 
                          in_instrument,
                          in_pollutant,
                          in_avg,
                          in_start,
                          in_end,
                          in_sensornumber,
                          in_cal,
                          met_variables) {
    lcs <- tbl(con, "lcs_hourly") %>%
        filter(instrument == in_instrument,
               measurand == in_pollutant,
               between(time, in_start, in_end),
               sensornumber == in_sensornumber,
               version == in_cal,
               is.na(flag) | flag != 'Error') %>%
        rename(lcs=measurement)
    # Obtain corresponding reference
    lcs <- lcs %>%
            inner_join(tbl(con, "ref_hourly") %>% select(-version) %>% rename(ref=measurement), 
                       by=c("location", "time", "measurand"))
    # Also download selected met variables
    # Create a dataframe containing all possible combinations of met factors, time, 
    # and location, then inner join this on what's available in the database
    time_locations <- lcs |> distinct(time, location) |> collect()
    ref_met <- tbl(con, "ref_hourly") |>
        filter(
            time %in% local(unique(time_locations$time)),
            location %in% local(unique(time_locations$location)),
            measurand %in% met_variables
        ) |>
        select(time, location, measurand, measurement) |>
        pivot_wider(names_from=measurand, values_from=measurement)
    lcs <- lcs %>% left_join(ref_met, by=c("time", "location"))
    
    if (in_avg == 'Daily') {
        lcs <- lcs %>%
                mutate(time = floor_date(time, "day")) %>%
                group_by(time, instrument, measurand, sensornumber, version, location) %>%
                summarise(lcs = mean(lcs, na.rm=T),
                          ref = mean(ref, na.rm=T),
                          across(met_variables, mean, na.rm=T)) %>%
                ungroup()
    }
    lcs %>% collect()
}

# Diagnostic plot functions
plot_residuals_time <- function(data, lcs_column="lcs", reference_column="reference", time_column="time") {
    data %>%
        dplyr::select(dplyr::all_of(c(time_column, lcs_column, reference_column))) %>%
        setNames(c('time', 'lcs', 'reference')) %>%
        dplyr::mutate(error = reference - lcs) %>%
        ggplot2::ggplot(ggplot2::aes(x=time, y=error)) +
            ggplot2::geom_abline(slope=0, intercept=0, colour="steelblue", size=0.7) +
            ggplot2::geom_line(na.rm=T) +
            ggplot2::theme_bw() +
            ggplot2::theme(
                panel.grid.minor = ggplot2::element_blank()
            ) +
            ggplot2::labs(x="", y="Error (reference - lcs)")
}

plot_residuals_fitted <- function(data, lcs_column="lcs", reference_column="reference") {
    data %>%
        dplyr::select(dplyr::all_of(c(lcs_column, reference_column))) %>%
        setNames(c('lcs', 'reference')) %>%
        dplyr::mutate(error = reference - lcs) %>%
        ggplot2::ggplot(ggplot2::aes(x=lcs, y=error)) +
        ggplot2::geom_abline(slope=0, intercept=0, colour="steelblue", size=0.7) +
        ggpointdensity::geom_pointdensity(na.rm=T) +
        ggplot2::geom_smooth(colour="red", na.rm=T) +
        ggplot2::scale_x_continuous(expand=ggplot2::expansion(c(0, 0.5))) +
        ggplot2::scale_y_continuous(expand=ggplot2::expansion(c(0, 0.5))) +
        ggplot2::theme_bw() +
        ggplot2::scale_colour_viridis_c() +
        ggplot2::guides(colour="none") +
        ggplot2::theme(
            panel.grid.minor = ggplot2::element_blank(),
            axis.title.x = ggplot2::element_text(size=10)
        ) +
        ggplot2::labs(x="[LCS]", y="Error (reference - lcs)")
}

plot_residuals_met <- function(data, lcs_column="lcs", reference_column="reference",
                               met_column="Temperature") {
    data %>%
        dplyr::select(dplyr::all_of(c(lcs_column, reference_column,  met_column))) %>%
        setNames(c('lcs', 'reference', 'met')) %>%
        dplyr::mutate(error = reference - lcs) %>%
        ggplot2::ggplot(ggplot2::aes(x=met, y=error)) +
        ggplot2::geom_abline(slope=0, intercept=0, colour="steelblue", size=0.7) +
        ggpointdensity::geom_pointdensity(na.rm=T) +
        ggplot2::geom_smooth(colour="red", na.rm=T) +
        ggplot2::scale_x_continuous(expand=ggplot2::expansion(c(0, 0.5))) +
        ggplot2::scale_y_continuous(expand=ggplot2::expansion(c(0, 0.5))) +
        ggplot2::theme_bw() +
        ggplot2::scale_colour_viridis_c() +
        ggplot2::guides(colour="none") +
        ggplot2::theme(
            panel.grid.minor = ggplot2::element_blank(),
            axis.title.x = ggplot2::element_text(size=10)
        ) +
        ggplot2::labs(x=met_column, y="Error (reference - lcs)")
}

########################################

server <- function(session, input, output) {
    
    con <- dbConnect(Postgres(),
                     dbname=CREDS$db,
                     host=CREDS$host,
                     port=CREDS$port,
                     user=CREDS$username,
                     password=CREDS$password)
    instruments <- tbl(con, "lcsinstrument") %>% 
                    filter(study == "QUANT")
    instrument_names <- instruments %>% select(instrument) %>% collect() %>% pull(instrument)
    instrument_names <- str_sort(instrument_names, numeric=TRUE)
    N_COMPARISONS <- 1
    dfs <- reactiveValues()
    
    
    ################################ Functions to dynamically create UI
    create_evaluation_row <- function(i) {
        div(
            fluidRow(
            box(
                title="Controls",
                selectInput(sprintf("instrument_select_%d", i),
                            "Select instrument",
                            choices=instrument_names),
                shiny::dateRangeInput(sprintf("date_%d", i),
                                      "Time-range",
                                      start=STUDY_START,
                                      end=STUDY_END,
                                      min=STUDY_START,
                                      max=STUDY_END),
                selectInput(sprintf("cal_%d", i),
                                    "Calibration version",
                                    choices=c("out-of-box")),
                selectInput(sprintf("sensornumber_%d", i),
                            "Sensor number", choices=c(1)),
                br(),
                br(),
                actionButton(sprintf("plot_%d", i),
                             "Plot"),
                hidden(downloadButton(sprintf("download_%d", i),
                             "Download data")),
                height=462.5,
                width=3,
                solidHeader = TRUE,
                status="success"
            ),
            box(
                title=div("Time-series", id=sprintf("box_timeseries_%d", i)),
                withSpinner(plotOutput(sprintf("timeseries_%d", i))),
                width=3,
                solidHeader = TRUE,
                status="primary"
            ),
            box(
                title=div("Regression", id=sprintf("box_scatter_%d", i)),
                withSpinner(plotOutput(sprintf("scatter_%d", i))),
                width=3,
                solidHeader = TRUE,
                status="primary"
            ),
            box(
                title=div("Bland-Altman", id=sprintf("box_ba_%d", i)),
                withSpinner(plotOutput(sprintf("ba_%d", i))),
                width=3,
                solidHeader = TRUE,
                status="primary"
            )
        ), id=sprintf("row_%d", i)
        )
    }

    create_plot_listener <- function(i) {
        observeEvent(input[[sprintf("plot_%d", i)]], {
            dates <- input[[sprintf("date_%d", i)]]
            dfs[[sprintf("df_%d", i)]] <- download_data(
                con,
                input[[sprintf("instrument_select_%d", i)]],
                input$measurand,
                input$timeavg,
                dates[1],
                dates[2],
                input[[sprintf("sensornumber_%d", i)]],
                input[[sprintf("cal_%d", i)]],
                MET_FIELDS
            )

            shinyjs::showElement(id=sprintf("download_%d", i))
        }, ignoreInit = TRUE)
    }
    
    create_evaluation_plot_renders <- function(i) {
        df_id <- sprintf("df_%d", i)
        
        # Time-series
        output[[sprintf("timeseries_%d", i)]] <- renderPlot({
            df <- dfs[[df_id]]
            req(df)
            shiny::validate(
                need(nrow(df) > 0,
                     "No datapoints found, check selection criteria."
                 )
            )
            if (input$plottype == 'Evaluation') {
                plot_time_series(df, lcs_column="lcs", reference_column="ref", time_column="time") +
                    guides(colour="legend") +
                    theme(legend.position = c(0.9, 0.9),
                          legend.background = element_rect(fill=NA))
            } else if (input$plottype == 'Diagnostic') {
                plot_residuals_time(df, lcs_column="lcs", reference_column="ref")
            }
        })
        
        # Scatter
        output[[sprintf("scatter_%d", i)]] <- renderPlot({
            df <- dfs[[df_id]]
            req(df)
            shiny::validate(
                need(nrow(df) > 0,
                     "No datapoints found, check selection criteria."
                 )
            )
            if (input$plottype == 'Evaluation') {
                suppressMessages(plot_scatter(df, lcs_column="lcs", reference_column="ref") + coord_cartesian())
            } else if (input$plottype == 'Diagnostic') {
                # The geom_smooth message is printed when the plot is rendered, not when
                # it is generated, unlike the message about overloading the coordinate system
                # in the scatter plot above
                p <- plot_residuals_fitted(df, lcs_column="lcs", reference_column="ref")
                suppressMessages(print(p))
            }
        })
        
        # Bland-Altman / residual vs met
        output[[sprintf("ba_%d", i)]] <- renderPlot({
            df <- dfs[[df_id]]
            req(df)
            shiny::validate(
                need(nrow(df) > 0,
                     "No datapoints found, check selection criteria."
                 )
            )
            if (input$plottype == 'Evaluation') {
                plot_bland_altman(df, lcs_column="lcs", reference_column="ref")
            } else if (input$plottype == 'Diagnostic') {
                p <- plot_residuals_met(df, lcs_column="lcs", reference_column="ref",
                                   met_column=input$met_diagnostic)
                suppressMessages(print(p))
            }
        })
    }
    
    create_update_selection_listeners <- function(i) {
        observeEvent(input[[sprintf("instrument_select_%d", i)]], {
            # Find sensornumbers and calibrationnames for this instrument
            inst <- input[[sprintf("instrument_select_%d", i)]]
            sensors <- tbl(con, "sensor") %>%
                filter(instrument == inst,
                       measurand == local(input$measurand)) %>%
                distinct(sensornumber) %>%
                collect() %>%
                pull(sensornumber)
            cals <- tbl(con, "sensorcalibration") %>%
                filter(instrument == inst,
                       measurand == local(input$measurand),
                       calibrationname != 'Rescraped') %>%
                arrange(dateapplied, calibrationname) %>%
                collect() %>%
                distinct(calibrationname) %>%
                pull(calibrationname)
            
            # Update UI choices
            updateSelectInput(session, sprintf("sensornumber_%d", i), choices=sensors)
            updateSelectInput(session, sprintf("cal_%d", i), choices=cals)
        })
    }

    create_download_handler <- function(i) {
        output[[sprintf("download_%d", i)]] <- downloadHandler(
            filename = function() {
                paste0(
                    paste(
                        "quant",
                        input[[sprintf("instrument_select_%d", i)]],
                        input$measurand,
                        input[[sprintf("date_%d", i)]][1],
                        input[[sprintf("date_%d", i)]][2],
                        input[[sprintf("cal_%d", i)]],
                        input[[sprintf("sensornumber_%d", i)]],
                        sep="_"
                    ),
                    ".csv"
                )
            },
            content = function(con) {
                lcs_col <- sprintf("%s_lcs", input$measurand)
                ref_col <- sprintf("%s_reference", input$measurand)
                df <- dfs[[sprintf("df_%d", i)]] %>% select(-measurand)
                colnames(df)[colnames(df) == 'lcs'] <- lcs_col
                colnames(df)[colnames(df) == 'ref'] <- ref_col
                write.csv(df, con, row.names = FALSE, quote = FALSE)
            }
        )
    }
    ############################ End functions to dynamically create plots

    output$deployment_plot <- renderPlot({
        df <- tbl(con, "deployment") %>%
                        inner_join(instruments, by="instrument") %>%
            collect() %>%
            mutate(
                   range = as.integer(difftime(finish, start, units="days")),
                   midpoint = as_date(start) + floor((range)/2)
            )
        instruments_descending <- str_sort(unique(df$instrument), numeric=TRUE, decreasing=TRUE)
        df %>%
            mutate(instrument = factor(instrument, levels=instruments_descending)) %>%
            ggplot(aes(x=midpoint, y=instrument, fill=location, width=range)) +
                geom_tile(na.rm=T) +
                theme_bw() +
                labs(x="", y="") +
                scale_x_date(date_breaks="4 months",
                             date_labels = "%b %y") +
                theme(panel.grid.major.x = element_blank(),
                      panel.grid.minor.x = element_blank(),
                      panel.grid.minor.y = element_blank(),
                      legend.text = element_text(size=10),
                      axis.text.x = element_text(size=10),
                      axis.text.y = element_text(size=9)) +
                scale_fill_discrete("") +
                theme(legend.position="bottom")
    })
    
    output$sensor_availability <- renderUI({
        # Obtain which sensors are housed in which instruments
        df <- tbl(con, "sensor") %>%
                inner_join(instruments, by="instrument") %>%
                filter(measurand %in% MEASURANDS) %>%
                select(instrument, measurand, sensornumber) %>%
                collect() 
        # Add missing gaps
        df <- expand_grid(instrument=unique(df$instrument), 
                    measurand=MEASURANDS) %>%
            left_join(df, by=c("instrument", "measurand")) %>%
            mutate(sensornumber = ifelse(is.na(sensornumber), 0, sensornumber)) %>%
            pivot_wider(names_from=measurand,
                        values_from=sensornumber,
                        values_fn=function(x) sum(x > 0)) %>%
            rename(Instrument = instrument) %>%
            mutate(across(-Instrument,
                   function(x) ifelse(x == 0, 'X', 
                                      ifelse(x == 1, '✓', x))))

        # Reorder both alphabetically and numerically (i.e. PA10 comes after PA2)
        instrument_order <- str_sort(unique(df$Instrument), numeric=TRUE)
        df <- df %>%
            mutate(Instrument = factor(Instrument, levels=instrument_order)) %>%
            arrange(Instrument)

        tab <- df %>%
            kable(align=c("l", rep("c", length(MEASURANDS)))) %>%
            kable_styling(c("striped", "hover")) 
        for (i in 2:ncol(df)) {
            tab <- tab %>% 
                column_spec(i,
                            background = ifelse(df[[i]] == 'X',
                                                'salmon',
                                                ifelse(df[[i]] == '✓', 'white', 'lightgreen')))
        }
        HTML(tab)
    })
    
    output$cal_versions <- renderPlot({
        df <- tbl(con, "sensorcalibration") %>%
            inner_join(instruments, by="instrument") %>%
            filter(calibrationname != 'Rescraped',
                   measurand %in% MEASURANDS) %>%
            group_by(company, measurand, calibrationname) %>%
            summarise(dateapplied = min(as_date(dateapplied), na.rm=T)) %>%
            collect() %>%
            ungroup() %>%
            arrange(company, dateapplied)
        
        df <- df %>%
            # It's possible to have simultaneous cals
            group_by(company, measurand, dateapplied) %>%
            summarise(calibrationname = paste(calibrationname, collapse=' + ')) %>%
            ungroup() %>%
            group_by(company, measurand) %>%
            mutate(
                end=lead(dateapplied, 1),
                end= as_date(ifelse(is.na(end), STUDY_END, end)),
                duration = as.numeric(difftime(end, dateapplied, units="days")),
                midpoint = dateapplied + (duration / 2)
            ) %>%
            ungroup()

        measurands_reversed <- str_sort(MEASURANDS, numeric=TRUE, decreasing=TRUE)
        
        df %>%
            mutate(measurand = factor(measurand, levels=measurands_reversed)) %>%
            ggplot() +
                geom_segment(aes(x=dateapplied,
                                 xend=end,
                                 y=measurand,
                                 yend=measurand,
                                 group=as.factor(calibrationname),
                                 colour=as.factor(calibrationname)),
                             alpha=0.5,
                             linewidth=5) +
                geom_text(aes(x=midpoint, y=measurand, label=calibrationname),
                          size=4) +
                facet_wrap(~company, ncol=1,
                           scales="free_y") +
                xlim(c(STUDY_START-10, STUDY_END)) +
                labs(x="", y="") +
                guides(colour="none") +
                theme_bw() +
                theme(
                    axis.text = element_text(size=10),
                    strip.text = element_text(size=12)
                )
    })
    
    
    # By default have the UI, output render functions, listener for 1 sensor
    output$evaluation_content <- renderUI({
        create_evaluation_row(1)
    })
    create_plot_listener(1)
    create_evaluation_plot_renders(1)
    create_download_handler(1)
    create_update_selection_listeners(1)
    
    ########################### Listeners to add/remove instrument boxes
    observeEvent(input$add_comparison, {
        N_COMPARISONS <<- N_COMPARISONS + 1
        # Insert UI and create plot renderers and button listeners
        new_row <- create_evaluation_row(N_COMPARISONS)
        insertUI("#evaluation_content",
                 "beforeEnd",
                 new_row,
                 immediate=FALSE
                 )
        create_plot_listener(N_COMPARISONS)
        create_evaluation_plot_renders(N_COMPARISONS)
        create_download_handler(N_COMPARISONS)
        create_update_selection_listeners(N_COMPARISONS)
        
        if (N_COMPARISONS == MAX_COMPARISONS) {
            disable("add_comparison")
            disable("copy_comparison")
        }
        if (N_COMPARISONS == 2) {
            enable("remove_comparison")
            enable("remove_all_comparison")
        }
    })

    observeEvent(input$copy_comparison, {
        N_COMPARISONS <<- N_COMPARISONS + 1
        # Insert UI and create plot renderers and button listeners
        new_row <- create_evaluation_row(N_COMPARISONS)
        insertUI("#evaluation_content",
                 "beforeEnd",
                 new_row,
                 immediate=TRUE
                 )
        updateSelectInput(session,
                          sprintf("instrument_select_%d", N_COMPARISONS),
                          selected = input[[sprintf("instrument_select_%d", N_COMPARISONS-1)]])
        updateDateRangeInput(session,
                             sprintf("date_%d", N_COMPARISONS),
                             start = input[[sprintf("date_%d", N_COMPARISONS-1)]][1],
                             end = input[[sprintf("date_%d", N_COMPARISONS-1)]][2]
                             )
        updateSelectInput(session,
                          sprintf("cal_%d", N_COMPARISONS),
                          selected = input[[sprintf("cal_%d", N_COMPARISONS-1)]])
        updateSelectInput(session,
                          sprintf("sensornumber_%d", N_COMPARISONS),
                          selected = input[[sprintf("sensornumber_%d", N_COMPARISONS-1)]])

        create_plot_listener(N_COMPARISONS)
        create_evaluation_plot_renders(N_COMPARISONS)
        create_download_handler(N_COMPARISONS)
        create_update_selection_listeners(N_COMPARISONS)

        if (N_COMPARISONS == MAX_COMPARISONS) {
            disable("add_comparison")
            disable("copy_comparison")
        }
        if (N_COMPARISONS == 2) {
            enable("remove_comparison")
            enable("remove_all_comparison")
        }
    })
    
    remove_row <- function(i) {
        removeUI(sprintf("#row_%d", i))
        dfs[[sprintf("df_%d", i)]] <- NULL
    }

    observeEvent(input$remove_comparison, {
        remove_row(N_COMPARISONS)
        N_COMPARISONS <<- N_COMPARISONS - 1
        if (N_COMPARISONS == 1) {
            enable("add_comparison")
            enable("copy_comparison")
            disable("remove_comparison")
            disable("remove_all_comparison")
        }
    })
    
    observeEvent(input$remove_all_comparison, {
        for (i in 2:N_COMPARISONS) {
            remove_row(i)
        }
        N_COMPARISONS <<- 1
        disable("remove_comparison")
        disable("remove_all_comparison")
        enable("add_comparison")
        enable("copy_comparison")
    })
    ########################### End listeners to add/remove instrument boxes
    
    output$measurand_selection <- renderUI({
        selectInput("measurand", "Pollutant",
                    choices=MEASURANDS)
    })
    
    output$met_selection <- renderUI({
        hidden(selectInput("met_diagnostic", "Met factor",
                    choices=MET_FIELDS))
    })
    
    # Only show the dropdown to select met factors when in diagnostic mode
    # TODO correctly display the met factor dropdown and the appropriate titles
    # when the page loads and is already in evaluation mode
    observeEvent(input$plottype, {
        if (input$plottype == 'Evaluation') {
            hideElement("met_diagnostic")
            for (i in seq(N_COMPARISONS)) {
                shinyjs::html(sprintf("box_timeseries_%d", i), "Time-series")
                shinyjs::html(sprintf("box_scatter_%d", i), "Regression")
                shinyjs::html(sprintf("box_ba_%d", i), "Bland-Altman")
            }
        } else if (input$plottype == 'Diagnostic') {
            showElement("met_diagnostic")
            for (i in seq(N_COMPARISONS)) {
                shinyjs::html(sprintf("box_timeseries_%d", i), "Error against time")
                shinyjs::html(sprintf("box_scatter_%d", i), "Error against LCS")
                shinyjs::html(sprintf("box_ba_%d", i), "Error against meteorological factor")
            }
        }
    }, ignoreInit = FALSE, ignoreNULL = TRUE)
    
    # Redownload data when measurand / or time resolution changes
    observeEvent(
        {
            input$measurand
            input$timeavg
        },
        {
            for (i in seq(N_COMPARISONS)) {
                dates <- input[[sprintf("date_%d", i)]]
                dfs[[sprintf("df_%d", i)]] <- download_data(
                    con,
                    input[[sprintf("instrument_select_%d", i)]],
                    input$measurand,
                    input$timeavg,
                    dates[1],
                    dates[2],
                    input[[sprintf("sensornumber_%d", i)]],
                    input[[sprintf("cal_%d", i)]],
                    MET_FIELDS
                )
            }
        }, ignoreInit = TRUE)
}