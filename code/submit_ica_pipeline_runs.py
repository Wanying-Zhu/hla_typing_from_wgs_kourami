# Plan to run 10 samples per submission, and submit at 36 second interval
# So there will be roughly 100 running at any time
# Usage;
# python submit_ica_pipeline_runs.py <resume_from_Nth_command>

import subprocess
import time
import logging
import sys

# Resume run from the Nth command (1 base)
try:
    resume_from = int(sys.argv[1])
except:
    resume_from = 1 # Default to the 1st command
    

# ---------------- CONFIGURATION ----------------
COMMAND_FILE = "./bash_slurm/icav2_pipeline_run.extract_hla_reads.sh"
LOG_FILE = "ica_pipeline_runner.log"
COMMANDS_PER_HOUR = 100 # Assume I want this number of commands to be submitted per hour
SECONDS_PER_HOUR = 3600
# Calculate ideal delay: 36.0 seconds per command
DELAY_BETWEEN_COMMANDS = SECONDS_PER_HOUR / COMMANDS_PER_HOUR 
# -----------------------------------------------

# Set up logging to track progress and errors
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler() # Also print to console
    ]
)

def run_commands():
    # Read all commands, ignoring empty lines and bash comments
    with open(COMMAND_FILE, 'r') as file:
        commands = [line.strip() for line in file if line.strip() and not line.startswith('#')]
    
    total_commands = len(commands)
    logging.info(f"# Loaded {total_commands} commands. Estimated time: {total_commands * DELAY_BETWEEN_COMMANDS / 3600:.2f} hours.")

    for i, cmd in enumerate(commands, start=1):
        if i < resume_from:
            logging.info(f"# [{i}/{total_commands}] Skipping command")
            continue

        start_time = time.time()
        
        logging.info(f"# [{i}/{total_commands}] Submitting ica command")
        
        try:
            # Execute the bash command
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode != 0:
                logging.error(f"# - Failed (Exit Code {result.returncode}): {result.stderr.strip()}")
            else:
                logging.info("# - Success.")
                
        except Exception as e:
            logging.error(f"# - System Exception: {e}")

        # Calculate how long the command took to run
        elapsed_time = time.time() - start_time
        
        # Sleep for the remainder of the 36-second window
        # max(0, ...) ensures we don't sleep for a negative time if a command took longer than 36s
        sleep_time = max(0, DELAY_BETWEEN_COMMANDS - elapsed_time)
        
        if i < total_commands:
            logging.info(f"# - Waiting {sleep_time:.2f}s until next execution...\n")
            time.sleep(sleep_time)

if __name__ == "__main__":
    try:
        run_commands()
        logging.info("# All commands executed successfully.")
    except KeyboardInterrupt:
        logging.warning("# Execution paused by user (Ctrl+C).")