library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinycssloaders)

ui <- dashboardPage(
    dashboardHeader(title = "QUANT"),
    dashboardSidebar(
            sidebarMenu(
                HTML("<a><img src= 'UOY.jpg'></img></a>"),
                menuItem("Evaluation", tabName="evaluation", icon=icon("chart-simple")),
                menuItem("Devices", tabName="devices", icon=icon("microscope")),
                menuItem("About", tabName="about", icon=icon("house")),
                menuItem("Own Data Evaluation", tabName="input", icon=icon("arrow-up-from-bracket") ),
               
                
               HTML(paste0(
                   "<br><br>
                   <table style = 'margin-left:auto; margin-right:auto; margin-bottom; 50px'>
                   <tr>
                   <td style = 'padding: 6px; font-size:24px;'><small><a href = 'mailto:wacl@york.ac.uk'><i class='fas fa-mail-bulk'></i></a></small></td>
                   <td style = 'padding: 6px; font-size:24px;'><small><a href= 'https://x.com/@AtmosChemYork'><i class='fab fa-twitter'></i></a></small></td>
                   <td style = 'padding: 6px; font-size:24px;'><small><a href= 'tel:1904 322609'><i class='fas fa-phone'></i></a></small></td>
                   </tr>
                   </table>
                   <p style = 'text-align: center;'><small><a href='https://www.york.ac.uk/chemistry/research/wacl/' >WACL</a> </small></p>")
               )
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
            tabItem(tabName="input",
                    h2("Compare your own sampled data"),
                    box(title = "Upload the file of your data",
                        p("Data needs to be in an excel sheet."),
                        p("Excel sheet needs the headings of the columns to be instrument, concentration, date, etc."),
                        status="info",
                        solidHeader = TRUE,
                        width = 12,
                        fluidRow(
                            column(
                                3,
                                
                               fileInput("add_data", "Add data", accept = ".xlsx")
                            ),
                            column(
                                3,
                                uiOutput("selected_option"), #choose pollutant type,
                                
                            ),
                            column(
                                3,
                                br(),
                                downloadButton("report", "Generate Report"), #button to download report
                            )
                        ),
                      
                        br(),
                    ),
                    fluidRow(box(
                        title="Plot",
                           
                            plotOutput("inputted_plot"),
                        
                        width=12
                        
                    ))
                     
                    
                    ),
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
                            column(
                                3,
                                uiOutput("selected_device"), #choose device to see history of
                            ),

                                plotOutput("specdevice_deployment_plot"), #outputs specific device timeline
br(), br(),br(),br(),
p("All devices deployment history"),
                           withSpinner(
                                plotOutput("deployment_plot"),
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
