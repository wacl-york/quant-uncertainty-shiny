library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinycssloaders)

ui <- dashboardPage(

    dashboardHeader(title="QUANT"),
    dashboardSidebar(
            sidebarMenu(
                menuItem("About", tabName="about", icon=icon("house")),
                menuItem("Devices", tabName="devices", icon=icon("microscope")),
                menuItem("Evaluation", tabName="evaluation", icon=icon("chart-simple")),
                menuItem("Diagnostics", tabName="diagnostics", icon=icon("wrench"))
            )
    ),
    dashboardBody(
        useShinyjs(),
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
                    fluidRow(
                        # TODO clean up into a single row
                        actionButton("add_comparison", "Add device"),
                        actionButton("copy_comparison", "Copy last device"),
                        disabled(actionButton("remove_comparison", "Remove device")),
                        disabled(actionButton("remove_all_comparison", "Remove all devices")),
                        # TODO Add minutely
                        radioButtons("timeavg", "Time resolution", 
                                     choices=c("Hourly", "Daily"),
                                     selected="Hourly",
                                     inline=TRUE),
                        uiOutput("measurand_selection")
                    ),
                    br(),
                    uiOutput("evaluation_content")
            ),
            tabItem(tabName="diagnostics",
                    # TODO
                    # Error vs reference,
                    # Error vs time
                    h2("Diagnostics"),
            )
        )
    )
)