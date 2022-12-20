library(shiny)
library(shinydashboard)
library(shinycssloaders)

ui <- dashboardPage(

    dashboardHeader(title="QUANT"),
    dashboardSidebar(
            #tags$style(".skin-blue .sidebar .shiny-download-link { color: #444; }"),
            sidebarMenu(
                menuItem("About", tabName="about", icon=icon("house")),
                menuItem("Devices", tabName="devices", icon=icon("microscope")),
                menuItem("Evaluation", tabName="evaluation", icon=icon("chart-simple")),
                menuItem("Diagnostics", tabName="diagnostics", icon=icon("wrench"))
            )
            #radioButtons("species",
            #             "Species",
            #             choices=c("CO", "NO", "NO2", "O3", "PM1", "PM10", "PM2.5"),
            #             selected="NO2"),
            #dateRangeInput("daterange",
            #               "Time period",
            #               startview="year",
            #               min="2019-12-10",
            #               max=today(),
            #               end=today(),
            #               start="2019-12-10"),
            #radioButtons("location",
            #             "Location",
            #             choices=c("Manchester", "London", "York"),
            #             selected="Manchester"),
            #sliderInput("avg",
            #             "Minute average",
            #             value=60,
            #             min=1,
            #             max=60),
            #checkboxInput("calibrate", "Recalibrate"),
            #checkboxGroupInput("devices",
            #                   "Devices",
            #                   choices=all_devices),
            #actionButton("plot_button",
            #             "Plot"),
            #downloadButton("download_button", "Download displayed data")
    ),
    dashboardBody(
        tabItems(
            tabItem(tabName="about",
                    h1("QUANT"),
                    p("Some information about the study here")
            ),
            tabItem(tabName="devices",
                    h1("Particpating devices"),
                    fluidRow(
                        box(
                            title="Device deployment history",
                            withSpinner(
                                plotOutput("deployment_plot")
                            ),
                            width=12
                        ),
                        box(
                            title="Available sensors",
                            withSpinner(
                                htmlOutput("sensor_availability")
                            ),
                            width=12
                        ),
                        box(
                            title="Calibration versions",
                            withSpinner(
                                plotOutput("cal_versions")
                            ),
                            width=12
                        )
                    )
            ),
            tabItem(tabName="evaluation",
                    h2("Evaluation"),
                    p("Scatter/REU/BA")
            ),
            tabItem(tabName="diagnostics",
                    h2("Diagnostics"),
                    p("Error vs time etc...")
            )
        )
        #fluidRow(
        #    box(
        #        title="Time series",
        #        withSpinner(
        #            plotOutput("time_ref")
        #        ), 
        #        width=12
        #    ),
        #),
        #fluidRow(
        #    box(
        #        title="Scatter",
        #        withSpinner(
        #            plotOutput("scatter")
        #        ), 
        #        width=12
        #    ),
        #),
        #fluidRow(
        #    column(
        #        radioButtons("error_type",
        #                     "Error type",
        #                     choices=c("Absolute (ref - LCS)"="absolute", "REU (GDE)"="REU"),
        #                     selected="absolute"),
        #        width=3
        #    ),
        #    column(
        #        numericInput("min_reu",
        #                     "Minimum REU to display",
        #                     value=0),
        #        width=3
        #    ),
        #    column(
        #        numericInput("max_reu",
        #                     "Maximum REU to display",
        #                     value=200,
        #                     min=100),
        #        width=3
        #    )
        #),
        #fluidRow(
        #    box(
        #        title="Error vs time",
        #        withSpinner(
        #            plotOutput("time_plot")
        #        ),
        #        width=12
        #    )
        #),
        #fluidRow(
        #    box(
        #        title="Error vs concentration",
        #        withSpinner(
        #            plotOutput("conc_plot"),
        #        ),
        #        width=12
        #    ),
        #),
    )
)