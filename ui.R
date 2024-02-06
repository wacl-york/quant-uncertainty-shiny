library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinycssloaders)

ui <- dashboardPage(
    dashboardHeader(title="QUANT"),
    dashboardSidebar(
            sidebarMenu(
                menuItem("Evaluation", tabName="evaluation", icon=icon("chart-simple")),
                menuItem("Devices", tabName="devices", icon=icon("microscope")),
                menuItem("About", tabName="about", icon=icon("house"))
            )
    ),
    dashboardBody(
        useShinyjs(),
        tags$head(
            tags$script(
                src = "https://www.googletagmanager.com/gtag/js?id=G-BYGZTN7CNN",
                async = ""
            ),
            tags$script(
                src = "static/js/gtag.js"
            )
        ),
        tabItems(
            tabItem(tabName="about",
                    h1("Quantification of Utility of Atmospheric Network Technologies: (QUANT)"),
                    p("This dashboard is still under active development and is currently in a beta state. We hope to finalise the app soon.
                      As such the dataset is currently limited to the main study participants, with the Wider Participation data being made available at a later date."),
                    p("If you have any questions about the dashboard, please contact Stuart Lacy (stuart.lacy@york.ac.uk), while any questions about the study itself should be directed to Pete Edwards (pete.edwards@york.ac.uk).")
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
                            title="Calibration versions",
                            withSpinner(
                                plotOutput("cal_versions")
                            ),
                            width=12
                        ),
                        box(
                            title="Available sensors",
                            withSpinner(
                                htmlOutput("sensor_availability")
                            ),
                            width=12
                        )
                    )
            ),
            tabItem(tabName="evaluation",
                    h2("Compare devices"),
                    # TODO Add minutely
                    box(title = "Settings",
                        status="info",
                        solidHeader = TRUE,
                        actionButton("add_comparison", "Add device"),
                        actionButton("copy_comparison", "Copy last device"),
                        disabled(actionButton("remove_comparison", "Remove device")),
                        disabled(actionButton("remove_all_comparison", "Remove all devices")),
                        br(),
                        fluidRow(
                            column(
                                3,
                                radioButtons("timeavg", "Time resolution",
                                             choices=c("Hourly", "Daily"),
                                             selected="Hourly",
                                             inline=TRUE)
                            ),
                            column(
                                3,
                                uiOutput("measurand_selection"),
                            ),
                            column(
                                3,
                                radioButtons("plottype", "Plot type",
                                             choices=c("Evaluation", "Diagnostic"),
                                             selected="Evaluation", inline=TRUE),
                            ),
                            column(
                                3,
                                uiOutput("met_selection")
                            ),
                        ),
                        width=12
                    ),
                    br(),
                    uiOutput("evaluation_content")
            )
        )
    )
)
