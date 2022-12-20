library(DBI)
library(odbc)
library(knitr)
library(kableExtra)
library(RSQLite)
library(shiny)
library(tidyverse)
library(lubridate)
library(ggpubr)

MEASURANDS <- c("NO2", "O3", "PM2.5")
STUDY_START <- as_date("2019-12-10")
STUDY_END <- as_date("2022-10-31")

#sidebar <- dashboardSidebar(
#    sidebarMenu(
#        #menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
#        #menuItem("Widgets", icon = icon("th"), tabName = "widgets",
#        #         badgeLabel = "new", badgeColor = "green")
#                 menuItem("About", tabname="about", icon=icon("house")),
#                 menuItem("Devices", tabname="devices", icon=icon("microscope")),
#                 menuItem("Evaluation", tabname="evaluation", icon=icon("chart-simple")),
#                 menuItem("Diagnostics", tabname="diagnostics", icon=icon("wrench"))
#    )
#)
#
#body <- dashboardBody(
#    tabItems(
#        tabItem(tabName = "dashboard",
#                h2("Dashboard tab content")
#        ),
#        
#        tabItem(tabName = "widgets",
#                h2("Widgets tab content")
#        )
#    )
#)
#
## Put them together into a dashboardPage
#ui <- dashboardPage(
#    dashboardHeader(title = "Simple tabs"),
#    sidebar,
#    body
#)

server <- function(input, output) {
    
    con <- dbConnect(odbc(), "QUANT")  # TODO update to use credentials file
    instruments <- tbl(con, "lcsinstrument") |> 
                    filter(study == "QUANT")
    #lcs <- tbl(con, "lcs")
    #ref <- tbl(con, "ref")
    
    #selected_data <- eventReactive(input$plot_button, {
    #    start_time <- as.numeric(as_datetime(as_date(input$daterange[1])))
    #    end_time <- as.numeric(as_datetime(as_date(input$daterange[2] + 1)))
    #    avg_str <- sprintf("%d mins", input$avg)
    #    
    #    df <- lcs %>%
    #        filter(variable == !!input$species,
    #               device %in% !!input$devices,
    #               timestamp >= start_time,
    #               timestamp < end_time) %>%
    #        inner_join(deployments, by="device") %>%
    #        filter(timestamp >= start, timestamp <= end) %>%
    #        inner_join(ref, by=c("timestamp", "location", "variable")) %>%
    #        collect() %>%
    #        mutate(timestamp = floor_date(as_datetime(timestamp), avg_str)) %>%
    #        group_by(timestamp, device) %>%
    #        summarise(lcs = mean(lcs, na.rm=T),
    #                  reference = mean(reference, na.rm=T)) %>%
    #        ungroup()
    #    
    #    if (input$calibrate) {
    #        df <- df %>%
    #                  group_by(device) %>%
    #                  mutate(lcs = predict(lm(formula=reference ~ lcs), newdata=cur_data())) %>%
    #                  ungroup()
    #    }
    #    
    #    df
    #})
    #
    #horizontal_line_height <- reactive({
    #    if (input$error_type == "REU") {
    #        25
    #    } else if (input$error_type == "absolute") {
    #        0
    #    }
    #})
    #
    #error_data <- reactive({
    #    if (input$error_type == "REU") {
    #        err_func <- function(ref, lcs) {
    #            vals <- reu_gde(x=ref, y=lcs, Approach="GDE")
    #        }
    #    } else if (input$error_type == "absolute") {
    #        err_func <- function(ref, lcs) {
    #            ref - lcs
    #        }
    #    }
    #    selected_data() %>%
    #        group_by(device) %>%
    #        mutate(error = err_func(reference, lcs))
    #})
#
    #output$conc_plot <- renderPlot({
    #    df <- error_data()
    #    if (input$error_type == "REU") {
    #        df <- df %>%
    #            filter(error <= input$max_reu,
    #                   error >= input$min_reu)
    #    }
    #    df %>%
    #        ggplot(aes(x=reference, y=error)) +
    #            geom_point(na.rm=T) +
    #            geom_hline(yintercept = horizontal_line_height(), 
    #                       colour="green",
    #                       linetype="dashed") +
    #            stat_smooth(method="gam", formula=y ~ s(x, bs="cs")) +
    #            theme_bw() +
    #            labs(x="Reference (ppb)", y=sprintf("%s", input$error_type)) +
    #            facet_wrap(~device) 
    #})
    #
    #output$time_plot <- renderPlot({
    #    if (input$error_type == "REU") {
    #        summary_text <- error_data() %>%
    #            group_by(device) %>%
    #            summarise(lab = sprintf("Mean REU: %.2f%%", mean(error, na.rm=T)),
    #                      x=min(timestamp) + 0.80 * (max(timestamp) - min(timestamp)), y=Inf)
    #        
    #    } else if (input$error_type == "absolute") {
    #        summary_text <- error_data() %>%
    #            group_by(device) %>%
    #            summarise(lab = sprintf("RMSE: %.2f", sqrt(mean(error**2, na.rm=T))),
    #                      x=min(timestamp) + 0.80 * (max(timestamp) - min(timestamp)), y=Inf)
    #    }
    #    
    #    
    #    df <- error_data()
    #    if (input$error_type == "REU") {
    #        df <- df %>%
    #            filter(error <= input$max_reu,
    #                   error >= input$min_reu)
    #    }
    #    
    #    p <- df %>%
    #        ggplot(aes(x=timestamp, y=error)) +
    #            geom_line(na.rm=T) +
    #            geom_hline(yintercept = horizontal_line_height(), 
    #                       colour="green",
    #                       linetype="dashed") +
    #            geom_text(aes(label=lab, x=x, y=y), data=summary_text, vjust=1) +
    #            theme_bw() +
    #            labs(x="", y=sprintf("%s", input$error_type)) +
    #            facet_wrap(~device)
    #    
    #    
    #    p
    #    
    #})
    #
    #output$time_ref <- renderPlot({
    #    selected_data() %>%
    #        ggplot(aes(x=timestamp)) +
    #            geom_line(aes(y=lcs, colour="LCS"), na.rm=T) +
    #            geom_line(aes(y=reference, colour="Reference"), na.rm=T) +
    #            theme_bw() +
    #            theme(legend.position="bottom") +
    #            labs(x="", y=sprintf("%s", input$species)) +
    #            facet_wrap(~device) +
    #            scale_colour_manual("", values=c("Black", "Red"))
    #})
    #
    #output$scatter <- renderPlot({
    #    selected_data() %>%
    #        ggplot(aes(x=reference, y=lcs)) +
    #            geom_point(na.rm=T) +
    #            theme_bw() +
    #            labs(x="Reference", y="LCS") +
    #            geom_smooth(method="lm") +
    #            stat_regline_equation(
    #                aes(label =  paste(..eq.label.., ..rr.label.., sep = "~~~~")),
    #            ) + 
    #            facet_wrap(~device) 
    #})
    
    
    output$deployment_plot <- renderPlot({
        df <- tbl(con, "deployment") |>
                        inner_join(instruments, by="instrument") |>
            collect() |>
            mutate(
                   range = as.integer(difftime(finish, start, units="days")),
                   midpoint = as_date(start) + floor((range)/2),
                   instrument=as.factor(instrument)
            )
        instrument_ids <- rev(levels(df$instrument))
        df %>%
            ggplot(aes(x=midpoint, y=as.numeric(instrument), fill=location, width=range)) +
                geom_tile(na.rm=T) +
                theme_bw() +
                labs(x="", y="") +
                scale_x_date(date_breaks="4 months",
                             date_labels = "%b %y") +
                theme(panel.grid.major.x = element_blank(),
                      panel.grid.minor.x = element_blank(),
                      panel.grid.minor.y = element_blank()) +
                scale_y_continuous(breaks = 1:length(instrument_ids),
                                   labels = instrument_ids,
                                   sec.axis = dup_axis()) +
                scale_fill_discrete("") +
                theme(legend.position="bottom")
    })
    
    output$sensor_availability <- renderUI({
        # Obtain which sensors are housed in which instruments
        df <- tbl(con, "sensor") |>
                inner_join(instruments, by="instrument") |>
                filter(measurand %in% MEASURANDS) |>
                select(instrument, measurand, sensornumber) |>
                collect() 
        # Add missing gaps
        df <- expand_grid(instrument=unique(df$instrument), 
                    measurand=MEASURANDS) |>
            left_join(df, by=c("instrument", "measurand")) |>
            mutate(sensornumber = ifelse(is.na(sensornumber), 0, sensornumber)) |>
            pivot_wider(names_from=measurand,
                        values_from=sensornumber,
                        values_fn=sum) |>
            rename(Instrument = instrument) |>
            mutate(across(-Instrument,
                   function(x) ifelse(x == 0, 'X', 
                                      ifelse(x == 1, '✓', x))))
            
        tab <- df |>
            kable(align=c("l", rep("c", length(MEASURANDS)))) |>
            kable_styling(c("striped", "hover")) 
        for (i in 2:ncol(df)) {
            tab <- tab |> 
                column_spec(i,
                            background = ifelse(df[[i]] == 'X',
                                                'salmon',
                                                ifelse(df[[i]] == '✓', 'white', 'lightgreen')))
        }
        HTML(tab)
    })
    
    output$cal_versions <- renderPlot({
        df <- tbl(con, "sensorcalibration") |>
            inner_join(instruments, by="instrument") |>
            filter(calibrationname != 'Rescraped',
                   measurand %in% MEASURANDS) |>
            group_by(company, measurand, calibrationname) |>
            summarise(dateapplied = min(as_date(dateapplied), na.rm=T)) |>
            collect() |>
            ungroup() |>
            arrange(company, dateapplied)
        
        df <- df |>
            # It's possible to have simultaneous cals
            group_by(company, measurand, dateapplied) |>
            summarise(calibrationname = paste(calibrationname, collapse=' + ')) |>
            ungroup() |>
            group_by(company, measurand) |>
            mutate(duration = as.numeric(difftime(lead(dateapplied, 1), dateapplied, units="days")),
                   duration = ifelse(is.na(duration),
                                     as.numeric(difftime(STUDY_END, dateapplied, units="days")),
                                     duration),
                   midpoint = dateapplied + (duration / 2)) |>
            ungroup()
        
        df |>
            ggplot(aes(y=measurand)) +
                geom_tile(aes(x=dateapplied),
                          linewidth=2) +
                geom_text(aes(x=midpoint, label=calibrationname),
                          size=3) +
                facet_wrap(~company, ncol=1,
                           scales="free_y") +
                xlim(c(STUDY_START-10, STUDY_END)) +
                labs(x="", y="") +
                theme_bw()
    })
    
    #output$download_button <- downloadHandler(
    #    filename = function() {
    #        paste0("quant_extract_", Sys.Date(), ".csv")
    #    },
    #    content = function(file) {
    #        df <- selected_data() %>%
    #                group_by(device) %>%
    #                mutate(reu = reu_gde(x=reference, y=lcs, Approach="GDE"),
    #                       error = reference - lcs)
    #        write_csv(df, file)
    #    }
    #)
    
}