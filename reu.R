reu_gde <- function(x, y, Lambda = 1, u_xi = 0.0, Approach = 'GDE') {
    #NOTE: Sigma_err_x (NILU notation) is the same as u_xi (GDE2010 notation)
    Sigma_err_x = u_xi
    
    # Removing NaNs
    mask = !is.na(x) & !is.na(y)
    #x = x[mask]
    #y = y[mask]
    n = length(x)
    #Means
    x_mean = mean(x, na.rm=T)
    y_mean = mean(y, na.rm=T)
    #Variances
    S_x = var(x, na.rm=T)
    S_y = var(y, na.rm=T)
    #Covariances
    S_xy = mean(x*y, na.rm=T) - (x_mean * y_mean)
    #First step calculation of Slope and Intercept (bo & b1)
    #Slope (coeficient b1)
    btilde_1 = (S_y - Lambda*S_x + ((S_y - S_x)**2 + 4*Lambda*(S_xy**2))**(1/2))/(2*S_xy)
    #Intercept (coeficient bo):
    btilde_0 = y_mean - btilde_1*x_mean
    if (Approach == 'GDE') {
        #Equation error variance for y = b0 + b1*x + v_i
        rss = (y - btilde_0 - btilde_1*x)**2
        RSS = sum(rss, na.rm=T)
        Sigma_v_sqr = RSS/(n-2)
        #Error variance due to the deviation of the 1:1 line
        ec = (btilde_0 + (btilde_1 - 1)*x)**2
        REU = (2/y)*((Sigma_v_sqr - Sigma_err_x**2 + ec)**(1/2))*100
    } else {
        #Equation error variance for Y = b0 + b1*X + u_i
        v_i = y - btilde_0 - btilde_1*x #Eq. Error
        RSS_c = sum(v_i**2 - (btilde_1**2 + Lambda)*Sigma_err_x**2, na.rm=T)
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
        if (Approach == 'NILU1') {
            #Equation error variance for y = B0 + B1*x + v_i
            rss = (y - B0 - B1*x)**2
            RSS = sum(rss, na.rm=T)
            Sigma_v_sqr = RSS / (n-2)
            REU = (2/y) * ((Sigma_v_sqr - Sigma_err_x**2 + ec)**(1/2))*100   #Percentage
        } else if (Approach == 'NILU2') {
            #Measurement error variance corrected
            mec = (Lambda - (B1 - 1)**2)*Sigma_err_x**2
            REU = (2/y) * ((Sigma_u_sqr + mec + ec)**(1/2))*100   #Percentage
        }
    }
    REU
}
