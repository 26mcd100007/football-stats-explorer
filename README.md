# ⚽ Football Stats Explorer

An interactive football statistics dashboard developed using **R and Shiny**, inspired by football applications such as FotMob.

## Project Overview

Football Stats Explorer provides an interactive platform to explore football match results, league standings, team performance, and player statistics.

## Features

- **Match Centre:** View and search football match results.
- **League Table:** Calculate team rankings, wins, draws, losses, and points.
- **Team Insights:** Compare goals scored and conceded.
- **Top Scorers:** Explore player goals and assists.
- **Interactive Filters:** Filter matches by team, status, and date range.

## Technologies Used

- R Programming
- RStudio
- Shiny
- dplyr
- ggplot2
- DT
- CSV datasets

## Installation and Execution

Install the required packages:

```r
install.packages(c("shiny", "ggplot2", "dplyr", "DT"))
```

Open the project folder in RStudio and run:

```r
shiny::runApp()
```

## Project Structure

```text
football-stats-explorer/
├── app.R
├── matches.csv
├── scorers.csv
└── README.md
```

## Dataset Disclaimer

The included football match and player statistics are illustrative sample data and are not official live La Liga statistics.

## Author

Shayon Mahatma

MCA – Data Science
