library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinycssloaders)

ui <- dashboardPage(
    dashboardHeader(title = "QUANT"),
    dashboardSidebar(
            sidebarMenu(
                HTML("<a><img src= 'UOY.jpg' width = '230'></img></a>
                <br>
                     <a><img src= 'UKRI.jpg' width = '230'></img></a>"),
                menuItem("Evaluation", tabName="evaluation", icon=icon("chart-simple")),
                menuItem("Devices", tabName="devices", icon=icon("microscope")),
                menuItem("About", tabName="about", icon=icon("house")),
                # menuItem("Own Data Evaluation", tabName="input", icon=icon("arrow-up-from-bracket") ),
                menuItem("Device Reports", tabName="report", icon=icon("database")),
               
                
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
            tabItem(tabName="report",
                   
                    h2("Compare the QUANT devices data and generate their reports"),
                     
                    
                    HTML(paste0(
                        "<p>These reports contain an evaluation of the low-cost-sensor (LCS) units that were monitored as part of the QUANT study. The study performed a long-term evaluation of a subset of commercially available LCS for outdoor air pollution monitoring in background UK urban and roadside environments and focused on key pollutants of interest: nitrogen dioxide (NO2), ozone (O3), and particulate matter (PM). Five types of sensor devices were deployed: AQMesh (AQM), Aeroqual(AQY), Arisense(Ari), Purple Air(PA) and Zephyr(Zep). All devices started in Manchester and a representative amount of sensors were moved to either London or York. The two urban background sites were Manchester and London and the roadside site was in York. To ensure impartiality and consistency, device calibrations were performed by the manufacturers without any intervention from our team, and all reference data was embargoed until it was released to all manufacturers simultaneously.</p>
                        <br>
                        <p>The species under evaluation are whichever are available out of NO2, O3 and PM2.5. These are assessed on their accuracy by comparison to reference data by means of 3 methods:</p>
                        <ul>
                        <li>A time-series plot allowing for visual inspection of any longitudinal trends</li>
                        <li>A scatter plot assessing the linearity of the sensor system, along with the R2 and Root Mean Square Error (RMSE) summary metrics</li>
                        <li>A plot representing the drift of mean bias, RMSE, and Centred Root Mean Square Error (CRMSE)</li>
                        </ul>
                        <br>
                        <style>

                   .row {
                   display: flex;
                    margin-left:-2px;
                    margin-right:-2px;
                    
                    }
  
                   .column {
                  flex: 33%;
                   padding: 2%;
                }


                 .row::after {
                 clear: both;
                 display: table;
                 }
                 
                     .report{
                        table {
                        width:100%;
                        font-family: arial, sans-serif;
                        border-collapse: collapse;
                        border-spacing: 0;
                        
                        }

                        td, th {
                        width:33%;
                        border: 1px solid #dddddd;
                        text-align: left;
                         padding: 10px;
                        color:#003366;
                        }
                        
                     }
                     
                     .oddrow {
                     background-color: #e6ecff;
                     }
                     
                     .evenrow {
                      background-color: white;
                     }

                        
                        </style>
                        
                        <div class='row'>
                        <div class='column'>
                        <table class = 'report'>
                        <tr class = 'oddrow'>
                        <th style = 'text-align:center;font-size:27px;'colspan='3'>Main Study Reports</th>
                        </tr>
                        <tr class = 'evenrow'>
                        <th>Device Make</th>
                        
                        <th>Meas.</th>
                        
                        <th>Summary Report </th>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3' ><a href='https://www.aeroqual.com/products/aqm-stations'>AQMesh</a></td>
                       
                        <td>NO2</td>
                        <td> ")),
                    
                    downloadLink("AQMeshNO2", "AQMesh NO2 Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>O3</td>
                        
                        <td>")),
                        
                        downloadLink("AQMeshO3", "AQMesh O3 Report"),
                        
                        HTML(paste0(
                         "</td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("AQMeshPM2.5", "AQMesh PM2.5 Report"),
                    
                    HTML(paste0(
                        "</td>
                        </tr>
                        
                        <tr class = 'evenrow'>
                        <td rowspan='3'><a href='https://www.aeroqual.com/products/aqy-r-series/aqy-r-air-quality-network-monitor'>Aeroqual</a></td>
                        
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("AeroqualNO2", "Aeroqual NO2 Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>O3</td>
                        
                        <td> ")),
                    
                    downloadLink("AeroqualO3", "Aeroqual O3 Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("AeroqualPM2.5", "Aeroqual PM2.5 Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3'><a href='https://www.arivalves.com/arisense'>Arisense</a></td>
                       
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("ArisenseNO2", "Arisense NO2 Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>O3</td>
                       
                        <td> ")),
                    
                    downloadLink("ArisenseO3", "Arisense O3 Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("ArisensePM2.5", "Arisense PM2.5 Report"),
                        
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        
                         <tr class = 'evenrow'>
                        <td ><a href='https://www2.purpleair.com/'>Purple Air</a></td>
                        
                        <td>PM2.5</td>
                        
                        <td>")),
                    
                    downloadLink("PurpleAir", "Purple Air Report"),
                        
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3'><a href='https://www.earthsense.co.uk/zephyr'>Zephyr</a></td>
                        
                        <td>NO2</td>
                        
                        <td>")),
                    
                    downloadLink("ZephyrNO2", "Zephyr NO2 Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>O3</td>
                        
                        <td> ")),
                    
                    downloadLink("ZephyrO3", "Zephyr O3 Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("ZephyrPM2.5", "Zephyr PM2.5 Report"),
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        </table>
                     </div>
                     
                    <div class='column'>
                                
                                <table class = 'report' >
                        <tr class = 'oddrow'>
                        <th style = 'text-align:center;font-size:27px;'colspan='3'>Wider Participation Reports</th>
                        </tr>
                        <tr class = 'evenrow'>
                        <th>Device Make</th>
                        
                        <th>Meas.</th>
                        
                        <th>Summary Report </th>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3' >Bosch</td>
                       
                        <td>NO2</td>
                        <td>")),
                    
                    downloadLink("NO2_Bosch", "NO2 Bosch Report"),
                    
                    HTML(paste0("
                         </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>O3</td>
                        
                        <td>")),
                    
                    downloadLink("O3_Bosch", "O3 Bosch Report"),
                    
                    HTML(paste0(
                        "</td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_Bosch", "PM2.5 Bosch Report"),
                    
                    HTML(paste0(
                        "</td>
                        </tr>
                        
                        <tr class = 'evenrow'>
                        <td rowspan='2'>Clarity</td>
                        
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_Clar", "NO2 Clarity Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_Clar", "PM2.5 Clarity Report"),
                    
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3'>EI (Environmental Instruments)</td>
                       
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_EI", "NO2 EI Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>O3</td>
                       
                        <td> ")),
                    
                    downloadLink("O3_EI", "O3 EI Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_EI", "PM2.5 Clarity Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'evenrow'>
                        <td rowspan='3'>Kunak (Kunak Technolgies)</td>
                       
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_Kunak", "NO2 Kunak Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>O3</td>
                       
                        <td> ")),
                    
                    downloadLink("O3_Kunak", "O3 Kunak Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_Kunak", "PM2.5 Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='1'>Modal Air</td>
                       
                        <td>PM2.5</td>
                       
                        <td>")),
                    
                    downloadLink("PM_Mod", "PM2.5 Modal Air Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'evenrow'>
                        <td rowspan='3'>Oizom</td>
                       
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_Oi", "NO2 Oizom Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>O3</td>
                       
                        <td> ")),
                    
                    downloadLink("O3_Oi", "O3 Oizom Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_Oi", "PM2.5 Oizom Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='1'>RLS (Urban Sciences)</td>
                       
                        <td>PM2.5</td>
                       
                        <td>")),
                    
                    downloadLink("PM_RLS", "PM2.5 RLS Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'evenrow'>
                        <td rowspan='3'>SCS (South Coast Sciences)</td>
                       
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_SCS", "NO2 SCS Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>O3</td>
                       
                        <td> ")),
                    
                    downloadLink("O3_SCS", "O3 SCS Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_SCS", "PM2.5 SCS Report"),
                    
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3'>Vortex (Vortex IoT)</td>
                       
                        <td>NO2</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_Vor", "NO2 Vortex Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>O3</td>
                       
                        <td> ")),
                    
                    downloadLink("O3_Vor", "O3 Vortex Report"),
                    
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>PM2.5</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_Vor", "PM2.5 Vortex Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                    
                           </table>
                            </div>
                            
                            <div class='column'>
                                
                                <table class = 'report'>
                        <tr class = 'oddrow'>
                        <th style = 'text-align:center;font-size:27px;'colspan='3'>Cross Company Reports</th>
                        </tr>
                        <tr class = 'evenrow'>
                        <th>Pollutant</th>
                        
                        <th>Location</th>
                        
                        <th>Summary Report </th>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3' >Particulate Matter (PM2.5)</td>
                       
                        <td>London</td>
                        <td>")),
                    
                    downloadLink("PM_London", "PM London Report"),
                    
                    HTML(paste0("
                         </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>Manchester</td>
                        
                        <td>")),
                    
                    downloadLink("PM_Manch", "PM Manchester Report"),
                    
                    HTML(paste0(
                        "</td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>York</td>
                        
                        <td> ")),
                    
                    downloadLink("PM_York", "PM York Report"),
                    
                    HTML(paste0(
                        "</td>
                        </tr>
                        
                        <tr class = 'evenrow'>
                        <td rowspan='3'>Nitrogen dioxide (NO2)</td>
                        
                        <td>London</td>
                       
                        <td>")),
                    
                    downloadLink("NO2_London", "NO2 London Report"),
                    
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>Manchester</td>
                        
                        <td> ")),
                    downloadLink("NO2_Manch", "NO2 Manchester Report"),
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'evenrow'>
                        <td>York</td>
                        
                        <td> ")),
                    downloadLink("NO2_York", "NO2 York Report"),
                    HTML(paste0("</td>
                        </tr>
                        
                        <tr class = 'oddrow'>
                        <td rowspan='3'>Ozone (O3)</td>
                       
                        <td>London</td>
                       
                        <td>")),
                    downloadLink("O3_London", "O3 London Report"),
                    HTML(paste0("
                        
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>Manchester</td>
                       
                        <td> ")),
                    downloadLink("O3_Manch", "O3 Manchester Report"),
                    HTML(paste0("
                        </td>
                        </tr>
                        <tr class = 'oddrow'>
                        <td>York</td>
                        
                        <td> ")),
                    downloadLink("O3_York", "O3 York Report"),
                    HTML(paste0("
                        </td>
                        </tr>
                        </table>
                        </div>
                        </div>"   
                    )
                    ),  
                        
                        
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

