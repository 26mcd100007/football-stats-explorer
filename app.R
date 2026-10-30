library(shiny)
library(ggplot2)
library(dplyr)
library(DT)

matches <- read.csv("matches.csv", stringsAsFactors = FALSE)
scorers <- read.csv("scorers.csv", stringsAsFactors = FALSE)
matches$Date <- as.Date(matches$Date)

make_standings <- function(data) {
  played <- data %>% filter(Status == "FINISHED")
  teams <- unique(c(played$Home, played$Away))

  result <- lapply(teams, function(team) {
    home <- played %>% filter(Home == team)
    away <- played %>% filter(Away == team)

    gf <- sum(home$HomeGoals) + sum(away$AwayGoals)
    ga <- sum(home$AwayGoals) + sum(away$HomeGoals)
    wins <- sum(home$HomeGoals > home$AwayGoals) +
      sum(away$AwayGoals > away$HomeGoals)
    draws <- sum(home$HomeGoals == home$AwayGoals) +
      sum(away$AwayGoals == away$HomeGoals)
    losses <- nrow(home) + nrow(away) - wins - draws

    data.frame(
      Team = team, Played = nrow(home) + nrow(away),
      Won = wins, Drawn = draws, Lost = losses,
      GF = gf, GA = ga, GD = gf - ga, Points = wins * 3 + draws
    )
  })

  bind_rows(result) %>%
    arrange(desc(Points), desc(GD), desc(GF)) %>%
    mutate(Position = row_number()) %>%
    select(Position, Team, Played, Won, Drawn, Lost, GF, GA, GD, Points)
}

standings <- make_standings(matches)

ui <- fluidPage(
  titlePanel("Football Stats Explorer | La Liga"),
  sidebarLayout(
    sidebarPanel(
      selectInput("team", "Select team",
                  choices = c("All teams", sort(unique(c(matches$Home, matches$Away))))),
      selectInput("status", "Match status", choices = c("All", unique(matches$Status))),
      dateRangeInput("dates", "Match date range",
                     start = min(matches$Date), end = max(matches$Date)),
      helpText("Offline CSV dashboard. Sample data is illustrative.")
    ),
    mainPanel(
      h3("La Liga Overview"),
      fluidRow(
        column(4, wellPanel("Matches", h3(textOutput("match_count")))),
        column(4, wellPanel("Completed", h3(textOutput("completed_count")))),
        column(4, wellPanel("Total goals", h3(textOutput("goal_count"))))
      ),
      tabsetPanel(
        tabPanel("Matches", br(), DTOutput("match_table")),
        tabPanel("Standings", br(), DTOutput("standing_table"), plotOutput("points_plot")),
        tabPanel("Team Analysis", br(), plotOutput("goals_plot"), plotOutput("results_plot")),
        tabPanel("Top Scorers", br(), DTOutput("scorer_table"), plotOutput("scorer_plot"))
      )
    )
  )
)

server <- function(input, output, session) {
  filtered_matches <- reactive({
    x <- matches
    if (input$team != "All teams") {
      x <- x %>% filter(Home == input$team | Away == input$team)
    }
    if (input$status != "All") {
      x <- x %>% filter(Status == input$status)
    }
    x %>% filter(Date >= input$dates[1], Date <= input$dates[2])
  })

  output$match_count <- renderText(nrow(filtered_matches()))
  output$completed_count <- renderText(sum(filtered_matches()$Status == "FINISHED"))
  output$goal_count <- renderText({
    x <- filtered_matches() %>% filter(Status == "FINISHED")
    sum(x$HomeGoals + x$AwayGoals)
  })

  output$match_table <- renderDT(datatable(filtered_matches(), rownames = FALSE))
  output$standing_table <- renderDT(datatable(standings, rownames = FALSE))

  output$points_plot <- renderPlot({
    ggplot(standings, aes(x = reorder(Team, Points), y = Points)) +
      geom_col(fill = "steelblue") + coord_flip() +
      labs(title = "League Points by Team", x = "Team", y = "Points") +
      theme_minimal()
  })

  output$goals_plot <- renderPlot({
    goals <- bind_rows(
      data.frame(Team = standings$Team, Type = "Goals scored", Goals = standings$GF),
      data.frame(Team = standings$Team, Type = "Goals conceded", Goals = standings$GA)
    )
    ggplot(goals, aes(x = reorder(Team, Goals), y = Goals, fill = Type)) +
      geom_col(position = "dodge") + coord_flip() +
      labs(title = "Goals Scored vs Goals Conceded", x = "Team", y = "Goals") +
      theme_minimal()
  })

  output$results_plot <- renderPlot({
    x <- filtered_matches() %>% filter(Status == "FINISHED")
    validate(need(nrow(x) > 0, "No completed matches selected."))
    result <- ifelse(x$HomeGoals > x$AwayGoals, "Home win",
                     ifelse(x$HomeGoals < x$AwayGoals, "Away win", "Draw"))
    result_data <- as.data.frame(table(result))
    names(result_data) <- c("Result", "Count")
    ggplot(result_data, aes(x = Result, y = Count, fill = Result)) +
      geom_col() + labs(title = "Match Result Distribution",
                        x = "Result", y = "Number of matches") +
      theme_minimal()
  })

  output$scorer_table <- renderDT(datatable(scorers %>% arrange(desc(Goals)), rownames = FALSE))
  output$scorer_plot <- renderPlot({
    ggplot(scorers, aes(x = reorder(Player, Goals), y = Goals)) +
      geom_col(fill = "darkgreen") + coord_flip() +
      labs(title = "Top Scorers", x = "Player", y = "Goals") +
      theme_minimal()
  })
}

shinyApp(ui, server)
