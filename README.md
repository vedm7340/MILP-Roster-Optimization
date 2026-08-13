# MILP-Roster-Optimization

This is a comparative analysis of Mixed-Integer Linear Programming, Greedy, and Value-Per-Dollar Heuristic approaches to NBA roster construction under salary cap, minute, and position constraints. 

Implemented in Julia using JuMP and HiGHS.

### Key Findings ###
- MILP produces approximately a 50.5% improvement over the Heuristic baseline
- MILP produces approximately a 25.7% improvement over the Greedy baseline
- Non-monotonic scalability behavior observed across pool sizes of 70 to 370 players attributable to LP relaxation tightness
- Structural divergence from the championship roster team attributable to additive objective function limitations

### Repository Structure ###
- Src/ - Julia Source Files (MILP, Greedy, Heuristic, Scalability)
- Data/ - Raw and Cleaned datasets for the 2025-2026 NBA season
- Graphs/ - Scalability, Sensitivity, and Algorithm Comparison Analysis Graph
- Notebooks/ - Exploratory analysis code and Pearson's r derivation

### Paper ###
- The full research paper is available to view in this repository
