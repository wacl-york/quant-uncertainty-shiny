library(DBI)
library(RSQLite)
library(shiny)
library(tidyverse)
library(lubridate)
library(shinydashboard)
library(shinycssloaders)

all_devices <- c(
    "AQM388",
    "AQM389",
    "AQM390",
    "AQM391",
    "AQY872",
    "AQY873A",
    "AQY874",
    "AQY875A2",
    "Ari063",
    "Ari078",
    "Ari086",
    "Ari093",
    "Ari096",
    "PA1",
    "PA2",
    "PA3",
    "PA4",
    "PA5",
    "PA6",
    "PA7",
    "PA8",
    "PA9",
    "PA10",
    "Zep188",
    "Zep309",
    "Zep311",
    "Zep344",
    "Zep716"
)


ui <- dashboardPage(

    dashboardHeader(title="QUANT LCS Uncertainty"),
    dashboardSidebar(
            radioButtons("species",
                         "Species",
                         choices=c("CO", "NO", "NO2", "O3", "PM1", "PM10", "PM2.5"),
                         selected="NO2"),
            dateRangeInput("daterange",
                           "Time period",
                           startview="year",
                           min="2019-12-10",
                           max=today(),
                           end=today(),
                           start="2019-12-10"),
            radioButtons("location",
                         "Location",
                         choices=c("Manchester", "London", "York"),
                         selected="Manchester"),
            sliderInput("avg",
                         "Minute average",
                         value=1,
                         min=1,
                         max=60),
            checkboxInput("calibrate", "Recalibrate"),
            numericInput("max_reu",
                         "Maximum REU to display",
                         value=200,
                         min=100),
            checkboxGroupInput("devices",
                               "Devices",
                               choices=all_devices),
            actionButton("plot_button",
                         "Plot")
    ),
    dashboardBody(
        fluidRow(
            box(
                title="REU",
                withSpinner(
                    plotOutput("reu_plot"),
                )
            ),
        ),
        fluidRow(
            box(
                title="Residuals",
                withSpinner(
                    plotOutput("residual_plot")
                )
            )
        ),
        fluidRow(
            box(
                title="Device deployment history",
                withSpinner(
                    plotOutput("deployment_plot")
                )
            )
        )
    )
)

reticulate::use_condaenv("datascience")
REU_mod <- reticulate::import("REU_Global_func")
REU <- REU_mod$REU

server <- function(input, output) {
    
    con <- dbConnect(RSQLite::SQLite(), "quant.db")
    lcs <- tbl(con, "lcs")
    ref <- tbl(con, "reference")
    deployments <- tbl(con, "deployments")
    
    selected_data <- eventReactive(input$plot_button, {
        start_time <- as.numeric(as_datetime(as_date(input$daterange[1])))
        end_time <- as.numeric(as_datetime(as_date(input$daterange[2] + 1)))
        avg_str <- sprintf("%d mins", input$avg)
        
        df <- lcs %>%
            filter(variable == !!input$species,
                   device %in% !!input$devices,
                   timestamp >= start_time,
                   timestamp < end_time) %>%
            inner_join(deployments, by="device") %>%
            filter(timestamp >= start, timestamp <= end) %>%
            inner_join(ref, by=c("timestamp", "location", "variable")) %>%
            collect() %>%
            mutate(timestamp = floor_date(as_datetime(timestamp), avg_str)) %>%
            group_by(timestamp, location, manufacturer, device) %>%
            summarise(lcs = mean(lcs, na.rm=T),
                      reference = mean(reference, na.rm=T)) %>%
            mutate(residual = reference - lcs) %>%
            ungroup()
        
        if (input$calibrate) {
            print("Recalibrating")
            df <- df %>%
                      group_by(location, manufacturer, device) %>%
                      mutate(lcs = lm(formula=reference ~ lcs)$fitted.values,
                             residual = reference - lcs) %>%
                      ungroup()
        }
        df
    })

    output$reu_plot <- renderPlot({
        reus <- REU(selected_data() %>% select(lcs, reference), "reference", Approach="GDE")
        
        selected_data() %>%
            mutate(reu = reus[["u_lcs"]]) %>%
            filter(reu < input$max_reu) %>%
            ggplot(aes(x=reference, y=reu)) +
                geom_point(na.rm=T) +
                stat_smooth(method="gam", formula=y ~ s(x, bs="cs")) +
                theme_bw() +
                labs(x="Reference (ppb)", y="REU (GDE)") +
                facet_wrap(~device, scales="free") +
                ylim(0, input$max_reu)
    })
    
    output$residual_plot <- renderPlot({
        rmses <- selected_data() %>%
            group_by(device) %>%
            summarise(rmse = sprintf("RMSE: %.2f", sqrt(mean(residual**2, na.rm=T))),
                      x=min(timestamp) + 0.80 * (max(timestamp) - min(timestamp)), y=1.3 * max(residual, na.rm=T))
        
        selected_data() %>%
            ggplot(aes(x=timestamp, y=residual)) +
                geom_line(na.rm=T) +
                geom_text(aes(label=rmse, x=x, y=y), data=rmses) +
                theme_bw() +
                labs(x="", y="Error: reference - lcs (ppb)") +
                facet_wrap(~device, scales="free")
    })
    
    output$deployment_plot <- renderPlot({
        deployments %>%
            collect() %>%
            mutate(start = as_date(start),
                   end = as_date(end),
                   range = as.integer(difftime(end, start, units="days")),
                   midpoint = start + floor((range)/2)) %>%
            ggplot(aes(x=midpoint, y=device, fill=location, width=range)) +
                geom_tile(na.rm=T) +
                theme_bw() +
                labs(x="", y="") +
                scale_fill_discrete("") +
                theme(legend.position="bottom")
    })
}

shinyApp(ui = ui, server = server)