#!/bin/sh

# ==========================================
#       AWS REGION DISCOVERY SCANNER
# ==========================================

# Get AWS profile from command-line argument
PROFILE="$1"

# Check profile argument
if [ -z "$PROFILE" ]; then
    echo "Usage: $0 <AWS_PROFILE>"
    echo "Example: $0 data_secrets"
    exit 1
fi

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# AWS regions (POSIX compatible list)
REGIONS="
us-east-1
us-east-2
us-west-1
us-west-2
af-south-1
ap-east-1
ap-south-1
ap-south-2
ap-northeast-1
ap-northeast-2
ap-northeast-3
ap-southeast-1
ap-southeast-2
ap-southeast-3
ap-southeast-4
ca-central-1
eu-central-1
eu-central-2
eu-west-1
eu-west-2
eu-west-3
eu-north-1
eu-south-1
eu-south-2
sa-east-1
"

# Counters
FOUND=0
EMPTY=0
NO_PERMISSION=0
ERRORS=0

# Banner
printf "${BOLD}${MAGENTA}"
echo "================================================"
echo "          AWS REGION DISCOVERY SCANNER"
echo "================================================"
printf "${NC}"

printf "${CYAN}AWS Profile: ${PROFILE}${NC}\n\n"

# Check AWS CLI
if ! command -v aws >/dev/null 2>&1; then
    printf "${RED}[ERROR] AWS CLI is not installed.${NC}\n"
    exit 1
fi

# Verify credentials
printf "${BLUE}[INFO] Checking AWS credentials...${NC}\n"

if ! aws sts get-caller-identity \
    --profile "$PROFILE" >/dev/null 2>&1; then

    printf "${RED}[ERROR] Credentials verification failed.${NC}\n"
    exit 1
fi

ACCOUNT=$(aws sts get-caller-identity \
    --profile "$PROFILE" \
    --query Account \
    --output text 2>/dev/null)

printf "${GREEN}[SUCCESS] AWS Account: ${ACCOUNT}${NC}\n\n"

# Scan regions
for region in $REGIONS; do

    printf "${BLUE}[SCANNING]${NC} ${YELLOW}${region}${NC}\n"

    result=$(aws ec2 describe-instances \
        --region "$region" \
        --profile "$PROFILE" \
        --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]" \
        --output text 2>&1)

    case "$result" in

        *UnauthorizedOperation*|*AccessDenied*)
            printf "${RED}[NO PERMISSION]${NC} %s\n" "$region"
            NO_PERMISSION=$((NO_PERMISSION + 1))
            ;;

        *AuthFailure*|*InvalidClientTokenId*|*ExpiredToken*)
            printf "${RED}[AUTHENTICATION ERROR]${NC} %s\n" "$region"
            ERRORS=$((ERRORS + 1))
            ;;

        *"Could not connect"*|*"Could not resolve"*)
            printf "${RED}[CONNECTION ERROR]${NC} %s\n" "$region"
            ERRORS=$((ERRORS + 1))
            ;;

        *"An error occurred"*)
            printf "${RED}[OTHER ERROR]${NC} %s\n" "$region"
            printf "%s\n" "$result"
            ERRORS=$((ERRORS + 1))
            ;;

        ""|None)
            printf "${YELLOW}[NO EC2 INSTANCES]${NC} %s\n" "$region"
            EMPTY=$((EMPTY + 1))
            ;;

        *)
            printf "${GREEN}[EC2 RESOURCES FOUND]${NC} %s\n" "$region"
            printf "${CYAN}%s${NC}\n" "$result"
            FOUND=$((FOUND + 1))
            ;;

    esac

    printf "${MAGENTA}----------------------------------------------${NC}\n"

done

# Summary
echo ""
printf "${BOLD}${MAGENTA}"
echo "============== SCAN SUMMARY =============="
printf "${NC}"

printf "${GREEN}Regions with EC2 instances : %s${NC}\n" "$FOUND"
printf "${YELLOW}Regions without instances  : %s${NC}\n" "$EMPTY"
printf "${RED}Permission denied          : %s${NC}\n" "$NO_PERMISSION"
printf "${RED}Other errors               : %s${NC}\n" "$ERRORS"

echo ""
printf "${BOLD}${GREEN}AWS REGION SCAN COMPLETED!${NC}\n"
printf "${MAGENTA}==========================================${NC}\n"
