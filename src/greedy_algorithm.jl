# Packages needed to process the CSV file and perform the staitstical calculations necessary
using CSV
using DataFrames
using Statistics

# Importing the CSV file necessary for the model
df = CSV.read("C:/Users/vedan/OneDrive/Desktop/data/all_players_cleaned_three_point_percentage.csv", DataFrame)

# Fill any remaining missing numeric values with that column's mean
for col in names(df)
    if eltype(df[!, col]) <: Union{Missing, Number}
        col_mean = mean(skipmissing(df[!, col]))
        df[!, col] = coalesce.(df[!, col], col_mean)
    end
end

# Create an array to store all of the player names
players = df.Player

# Setting up the salary cap and roster size manually instead of JuMP syntax
roster_size = 15
salary_cap = 155

# Statistics Pearson's R Values. 
# Values were determined in the statistics_pearsons_r file where the average statistic of every team was compared across the team wins
ppg_r = 0.494
per_r = 0.517
ws_r = 0.725
threepoint_percent_r = 0.337
assists_r = 0.292
games_r = 0.195
fouls_r = -0.301

# Adding up the absolute values of each Pearson's r coefficient
# abs function takes the absolute value of each variable
total_r = abs(ppg_r) + abs(per_r) + abs(ws_r) + abs(threepoint_percent_r) + abs(assists_r) + abs(games_r) + abs(fouls_r)

# Standardization of each statistic. This way, statistics with higher Pearson's r coefficient will have higher precedence over other statistics.
# Additonally, this is a good baseline for each of the statistics
# round function rounds the value to a certain digit
ppg_w = round(ppg_r/total_r, digits=3)
per_w = round(per_r/total_r, digits=3)
ws_w = round(ws_r/total_r, digits=3)
threepoint_percent_w = round(threepoint_percent_r/total_r, digits=3)
assists_w = round(assists_r/total_r, digits=3)
games_w = round(games_r/total_r, digits=3)
fouls_w = round(fouls_r/total_r, digits=3)

# Creation of the statistic that the DataFrame will be sorted by and the players will also be selected by
df[!, "Score"] = ppg_w .* df[!, "PTS"] .+ per_w .* df[!, "PER"] .+ ws_w .* df[!, "WS"] .+ threepoint_percent_w .* df[!, "3P%"] .+ assists_w .* df[!, "AST"] .+ games_w .* df[!, "G"] .+ fouls_w .* df[!, "PF"] 
sort!(df, "Score", rev=true)

# DataFrame that will store the selected players and variable that will store the remaining cap after each iteration
selected_players = similar(df, 0)
remaining_cap = salary_cap

# Variable to take in the start time of the model
time_start = time()

# For-Loop to iterate through the players
# Minute and Position constraints are intentionally omitted.
# This algorithm cannot enforce these globally as it would require
# look-ahead to guarantee position balance and minutes totals across the full roster.
# This illustrates why the greedy approach produces an unbalanced roster
# compared to MILP, which enforces all the constraints simultaneously.
for row in eachrow(df)
    # If the amount of selected players reaches 15, end the for-loop
    if nrow(selected_players) == roster_size
        break
    end
    
    # If the next player's salary is lesser than the remaining cap, then push that player onto the selected players DataFrame and subtract their salary from the remaining cap
    if row.Salary <= remaining_cap
        push!(selected_players, row)
        global remaining_cap -= row.Salary
    end
end

# Variable to take in the total time elapsed during the optimization
time_elapsed = time() - time_start
println("Time taken to solve the model (ms): ", round(time_elapsed * 1000, digits=3))

# To implement the salary floor in this algorithm, this if statement is written. 
# This serves as a warning rather than a strict constraint
if (salary_cap - remaining_cap) < 139
    println("Warning: salary cap constraint not satisfied! Total: $(salary_cap - remaining_cap)")
end

# Printing out the results of this algorithm
println("Selected Players: ", selected_players.Player)
println("Selected Players PPG: ", selected_players.PTS)
println("Selected Players PER: ", selected_players.PER)
println("Selected Players WS: ", selected_players.WS)
println("Selected Players 3P%: ", selected_players[!, "3P%"])
println("Selected Players APG: ", selected_players.AST)
println("Selected Players Total Games Played: ", selected_players.G)
println("Selected Players FPG: ", selected_players.PF)

greedy_score = sum(selected_players[!, "Score"])
println("Greedy Objective Score: ", round(greedy_score, digits=4))

println("Average Points: ", round(sum(selected_players.PTS)/nrow(selected_players), digits=1))
println("Average PER: ", round(sum(selected_players.PER)/nrow(selected_players), digits=1))
println("Average WS: ", round(sum(selected_players.WS)/nrow(selected_players), digits=1))
println("Average 3P%: ", round(sum(selected_players[!, "3P%"])/nrow(selected_players), digits=3))
println("Average APG: ", round(sum(selected_players.AST)/nrow(selected_players), digits=1))
println("Average Games Played: ", round(sum(selected_players.G)/nrow(selected_players), digits=1))
println("Average FPG: ", round(sum(selected_players.PF)/nrow(selected_players), digits=1))

println("Total Selected Players: ", nrow(selected_players))
println("Total Salary (M): ", round(sum(selected_players.Salary), digits=2))
println("Total Minutes: ", sum(selected_players.MP))