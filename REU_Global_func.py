import pandas as pd
import numpy as np
#import scipy.stats
#from scipy.stats import linregress
#from scipy.odr import *


#This function uses the standard_REU and is combined with the alternative_OLR
#For more details see Section 4, NILU report

def REU(DF, Ref, Lambda = 1, u_xi = 0.0, Approach = 'GDE'):
    
    #NOTE: Sigma_err_x (NILU notation) is the same as u_xi (GDE2010 notation)
    Sigma_err_x = u_xi
    
    list_ = []
    
    for Sensor in DF.columns[0:]:
        x = DF[Ref]
        y = DF[Sensor]
        
        #Masking the NaN's
        mask = ~np.isnan(x) & ~np.isnan(y)
        x = x[mask]
        y = y[mask]
        n = len(x)
        
        #Means
        x_mean = x.mean()
        y_mean = y.mean()

        #Variances
        S_x = x.var(ddof = 0)
        S_y = y.var(ddof = 0)

        #Covariances
        S_xy = ((x*y).mean()-(x.mean()*y.mean()))

        
        #First step calculation of Slope and Intercept (bo & b1)
        #Slope (coeficient b1)
        btilde_1 = (S_y - Lambda*S_x + ((S_y - S_x)**2 + 4*Lambda*(S_xy**2))**(1/2))/(2*S_xy)

        #Intercept (coeficient bo):
        btilde_0 = y_mean - btilde_1*x_mean
        

        if Approach == 'GDE':
            #Equation error variance for y = b0 + b1*x + v_i
            rss = (y - btilde_0 - btilde_1*x)**2
            RSS = rss.values.sum()
            Sigma_v_sqr = RSS/(n-2)
                
            #Error variance due to the deviation of the 1:1 line
            ec = (btilde_0 + (btilde_1 - 1)*x)**2
            
            REU = (2/y)*((Sigma_v_sqr - Sigma_err_x**2 + ec)**(1/2))*100
            
        else: 
            #Equation error variance for Y = b0 + b1*X + u_i
            v_i = y - btilde_0 - btilde_1*x #Eq. Error
            RSS_c = (v_i**2 - (btilde_1**2 + Lambda)*Sigma_err_x**2).values.sum() 
            Sigma_u_sqr = RSS_c/(n-2) 
            
            #Second step calculation of Slope and Intercept (Bo & B1)
            #Slope (coeficiente B1)
            # NO NEED TO SQUARE sigma_u_sqr again! It is calculated as squared in A.6 (appendix 2)
            B1 = (S_y - Lambda*S_x - Sigma_u_sqr + ((S_y - Lambda*S_x - Sigma_u_sqr)**2 + 4*Lambda*(S_xy**2))**(1/2))/(2*S_xy)
            #B1 = (S_y - Lambda*S_x - Sigma_u_sqr**2 + ((S_y - Lambda*S_x - Sigma_u_sqr**2)**2 + 4*Lambda*(S_xy**2))**(1/2))/(2*S_xy)
            
            #Intercept (coeficiente Bo):
            B0 = y_mean - B1*x_mean
                
            #Error variance due to the deviation of the 1:1 line
            ec = (B0 + (B1 - 1)*x)**2
            
            if Approach == 'NILU1':
                #Equation error variance for y = B0 + B1*x + v_i
                rss = (y - B0 - B1*x)**2
                RSS = rss.values.sum()
                Sigma_v_sqr = RSS/(n-2)
                        
                REU = (2/y)*((Sigma_v_sqr - Sigma_err_x**2 + ec)**(1/2))*100   #Percentage
                
            elif Approach == 'NILU2':
                #Measurement error variance corrected
                mec = (Lambda - (B1 - 1)**2)*Sigma_err_x**2
                        
                REU = (2/y)*((Sigma_u_sqr + mec + ec)**(1/2))*100   #Percentage
        
        list_.append(REU)
    
    REU = pd.concat(list_, axis=1)
    
    REU = pd.concat((DF[Ref], REU), axis=1)
    
    #Se generan los nombres de las columnas del datframe final. Para ello se emplean
    #las columnas originales del dataframe de entrada "DF", modificando todas las columnas,
    #excepto la columna con la medicion de referencia
    
    Col_Names=[DF.columns.tolist()[0]]
    for i in DF.columns.tolist()[0:]:
        i = 'u_'+ i
        Col_Names.append(i)
    REU.columns = Col_Names
    REU.rename_axis("Timestamp", axis='index', inplace=True)
    
    return REU


if __name__ == "__main__":
    #Prueba simple

    times = pd.date_range('2021-10-01', periods=11, freq='1min')
    NO2 = np.array([0.1, 10, 1, 2, 2, 6, 1, 5, 8, np.nan, 5])
    LC1 = np.array([0.2, 11, 2, 2, 3, 5, np.nan, 5, 8, 9, 4])
    LC2 = np.array([0.1, 9, 2, 2, 1, 4, 1, 5, np.nan, 8, 6])
    LC3 = np.array([0.4, 12, 0, 3, 1, 5, 2, np.nan, 6, 8, 6])
    my_array = np.transpose(np.array([NO2, LC1, LC2, LC3]))
    df = pd.DataFrame(my_array, columns = ['NO2', 'LC1', 'LC2', "LC3"], index = times)

    REU_df = REU(DF = df, Ref = 'NO2', Lambda = 1, u_xi = 0.0, Approach = 'NILU2')
    print(REU_df.head(11))
