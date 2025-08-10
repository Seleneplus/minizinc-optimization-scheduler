# Constraint-Based AI Agent Scheduling (MiniZinc)

This repo contains a **MiniZinc** constraint model for **agent (NPC) task scheduling** and **resource allocation** with **maintenance** constraints.  
It demonstrates **multi-objective optimization**: first **minimize maintenance load**, then **maximize executed task time**.

## Features
Uses set-based constraints to match service types with truck capabilities.
Incorporates sequence-dependent scheduling to handle maintenance cycles and major work restrictions.
Handles both normal and “dummy” trucks, the latter representing unassigned or skipped services.
Supports parameter sensitivity analysis by adjusting limits (e.g., minservice, minwork, maxsty) to test model robustness.

## Files
- `service_scheduling.mzn` – main MiniZinc model  
- `data/*.dzn` – sample datasets  
- `report/` – tested your scheduling model under different parameter configurations (like minservice, minwork, maxsty, maintdur, maxsep, prework, majorwork, etc.) and recorded how each setting affects feasibility, maintenance load, and service time.

## Run
1. Install MiniZinc.  
2. Open `service_scheduling.mzn` in MiniZinc IDE.  
3. Load a `.dzn` file from `data/` and **Run**.

## Applications
- **Game AI**: NPC/agent behavior scheduling & event allocation  
- Multi-agent resource planning  
- Real-world service & maintenance scheduling

## License
MIT

