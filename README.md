# VPN Client Migration to ra.oregon.gov VPN
Welcome to the VPN client migration repository for transitioning clients to the ra.oregon.gov VPN. This repository contains scripts designed to facilitate the migration process using SCCM compliance items. The scripts included here are meant to be executed both as the computer and the user to detect and remediate configuration changes as required.

## Files Included

### User Configuration Check and Remediation
- CI - Set USER F5 ra.oregon.gov config.ps1: This script is utilized for checking the user configuration related to the ra.oregon.gov VPN. Use flags to control behavior.
- CI - Set SYSTEM F5 ra.oregon.gov config.ps1: Use this script to check system configurations pertaining to the ra.oregon.gov VPN. Use flags to control behavior.

## Instructions
User Configuration Check:

- Run "CI - Set USER F5 ra.oregon.gov config.ps1" script as the user to check the user-specific configurations for ra.oregon.gov VPN.
- If changes are detected, utilize "CI - Set USER F5 ra.oregon.gov remediation.ps1" script to remediate the user configurations.
System Configuration Check:

- Execute "CI - Set SYSTEM F5 ra.oregon.gov config.ps1" script as the system to verify system-level configurations for ra.oregon.gov VPN.
- When system-level changes are required, employ "CI - Set SYSTEM F5 ra.oregon.gov remediation.ps1" script to remediate the system configurations.

## Important Notes

Ensure proper permissions and execution policies are set to run the scripts.
Test the scripts in a controlled environment before deploying them widely.
Monitor the migration process closely to address any unforeseen issues promptly.
For any assistance or inquiries, feel free to contact the repository maintainers.
Thank you for choosing the ra.oregon.gov VPN migration repository. Happy migrating! 
