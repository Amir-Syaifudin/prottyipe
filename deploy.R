# Deployment script for shinyapps.io or Posit Connect
library(rsconnect)

# Configure account (run once)
# rsconnect::setAccountInfo(name='your-account', token='your-token', secret='your-secret')

# Deploy application
rsconnect::deployApp(
  appDir = ".",
  appName = "si-prima-dashboard",
  appTitle = "SI-PRIMA Dashboard",
  launch.browser = TRUE,
  forceUpdate = TRUE
)
