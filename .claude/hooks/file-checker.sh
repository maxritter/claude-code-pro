#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ ${DEBUG_TIMING:-0} == "1" ]]; then
	start_time=$(date +%s%3N) # Time in milliseconds since epoch
	echo "🕐 Starting file checker at $(date)" >&2
fi

debug_timer() {
	if [[ ${DEBUG_TIMING:-0} == "1" ]]; then
		current_time=$(date +%s%3N) # Get time in milliseconds since epoch
		elapsed_ms=$((current_time - start_time))
		elapsed_sec=$((elapsed_ms / 1000))
		elapsed_frac=$((elapsed_ms % 1000))
		printf "⏱️  [%d.%03d s] %s\n" "$elapsed_sec" "$elapsed_frac" "$1" >&2
	fi
}

files=$(find . -maxdepth 6 -type f -mmin -1 \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.java" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.sh" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" \) -not -path "*/__pycache__/*" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/lib/*" -not -path "*/dist/*" -not -path "*/coverage/*" -not -path "*/test-reports/*" -not -path "*/cdk.out/*" -not -path "*/.terraform/*" -not -path "*/.terragrunt-cache/*" -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2)
if [[ -z $files ]]; then
	echo -e "${GREEN}✅ Code quality good. Continue${NC}" >&2
	exit 0
fi

debug_timer "File discovery completed: $files"

qlty_available=false
if command -v qlty >/dev/null 2>&1 && [[ -d ".qlty" ]]; then
	qlty_available=true
fi

ruff_format_applied=false
if [[ $files == *.py ]] && command -v ruff >/dev/null 2>&1; then
	debug_timer "Starting Python ruff formatting"
	ruff_format_output=$(ruff format "$files" 2>&1)
	if [[ $ruff_format_output == *"reformatted"* ]]; then
		ruff_format_applied=true
	fi

	ruff_fix_output=$(ruff check --fix "$files" 2>&1)
	if [[ $ruff_fix_output == *"fixed"* ]]; then
		ruff_format_applied=true
	fi
	debug_timer "Completed Python ruff formatting"
fi

project_dir=""
prettier_format_applied=false
eslint_format_applied=false

if [[ $files == *.ts ]] || [[ $files == *.tsx ]] || [[ $files == *.js ]] || [[ $files == *.jsx ]]; then
	debug_timer "Starting TypeScript/JavaScript formatting"
	if [[ $files == *"/infra/"* ]] && command -v npx >/dev/null 2>&1; then
		cd_dir=$(dirname "$files")
		while [[ $cd_dir != "/" ]] && [[ ! -f "$cd_dir/package.json" ]]; do
			cd_dir=$(dirname "$cd_dir")
		done

		if [[ -f "$cd_dir/package.json" ]]; then
			project_dir="$cd_dir"
			pushd "$project_dir" >/dev/null || exit

			if grep -q "projen" package.json 2>/dev/null; then
				eslint_fix_output=$(timeout 5 npx projen eslint --fix "$files" 2>&1 || true)
				if [[ $eslint_fix_output == *"fixed"* ]] || [[ $eslint_fix_output == *"formatted"* ]]; then
					eslint_format_applied=true
				fi
			elif [[ -f "eslint.config.mjs" ]] || [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]]; then
				eslint_fix_output=$(timeout 5 npx eslint --fix --cache "$files" 2>&1 || true)
				if [[ $eslint_fix_output == *"fixed"* ]]; then
					eslint_format_applied=true
				fi
			fi

			popd >/dev/null || exit
		fi
	fi
	debug_timer "Completed TypeScript/JavaScript formatting"
fi

fmt_output=""
check_output=""
check_exit_code=0
if [[ $qlty_available == true ]]; then
	debug_timer "Starting QLTY checks"
	fmt_output=$(qlty fmt "$files" 2>&1)
	check_output=$(qlty check --fix "$files" 2>&1)
	check_exit_code=$?
	debug_timer "Completed QLTY checks"
fi

ruff_output=""
pyright_output=""
ruff_exit_code=0
pyright_exit_code=0

if [[ $files == *.py ]]; then
	debug_timer "Starting Python linting checks"
	if command -v ruff >/dev/null 2>&1; then
		ruff_output=$(ruff check "$files" 2>&1)
		ruff_exit_code=$?
	fi

	if command -v pyright >/dev/null 2>&1; then
		pyright_output=$(pyright "$files" 2>&1)
		pyright_exit_code=$?
	fi
	debug_timer "Completed Python linting checks"
fi

eslint_output=""
tsc_output=""
awslint_output=""
eslint_exit_code=0
tsc_exit_code=0
awslint_exit_code=0

if [[ $files == *.ts ]] || [[ $files == *.tsx ]]; then
	debug_timer "Starting TypeScript linting and compilation checks"
	if [[ -n $project_dir ]]; then
		pushd "$project_dir" >/dev/null || exit

		relative_file=${files#"$project_dir"/}

		if [[ $eslint_format_applied != true ]]; then
			debug_timer "Starting ESLint check"
			if grep -q "projen" package.json 2>/dev/null; then
				eslint_output=$(timeout 3 npx projen eslint "$relative_file" 2>&1 || true)
				eslint_exit_code=$?
			elif [[ -f "eslint.config.mjs" ]] || [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]]; then
				eslint_output=$(timeout 3 npx eslint --cache "$relative_file" 2>&1 || true)
				eslint_exit_code=$?
			fi
			debug_timer "Completed ESLint check"
		fi

		if [[ -f "tsconfig.json" ]] && command -v npx >/dev/null 2>&1; then
			debug_timer "Starting TypeScript compilation check"
			tsc_output=$(timeout 2 npx tsc --noEmit --skipLibCheck --isolatedModules "$relative_file" 2>&1 || true)
			tsc_exit_code=$?
			if [[ $tsc_output == *"error TS"* ]] && [[ $tsc_output != *"TS2307"* ]] && [[ $tsc_output != *"TS2304"* ]]; then
				tsc_exit_code=1
			else
				tsc_exit_code=0
			fi
			debug_timer "Completed TypeScript compilation check"
		fi

		if grep -q "aws-cdk" package.json 2>/dev/null; then
			debug_timer "Starting awslint check"
			if command -v awslint >/dev/null 2>&1; then
				awslint_output=$(timeout 10 awslint 2>&1 || true)
				awslint_exit_code=$?
			elif grep -q '"awslint"' package.json 2>/dev/null; then
				awslint_output=$(timeout 10 npm run awslint 2>&1 || true)
				awslint_exit_code=$?
			fi
			debug_timer "Completed awslint check"
		fi

		popd >/dev/null || exit
	fi
	debug_timer "Completed TypeScript linting and compilation checks"
fi

terraform_fmt_output=""
terraform_fmt_applied=false

if [[ $files == *.tf ]]; then
	debug_timer "Starting Terraform checks"

	if command -v terraform >/dev/null 2>&1; then
		terraform_fmt_output=$(terraform fmt -check=false "$files" 2>&1)
		if [[ -n $terraform_fmt_output ]]; then
			terraform_fmt_applied=true
		fi
	fi

	debug_timer "Completed Terraform checks"
fi

cfn_lint_output=""
cfn_lint_exit_code=0

if [[ $files == *.yaml ]] || [[ $files == *.yml ]]; then
	debug_timer "Starting CloudFormation lint"

	if grep -q "AWSTemplateFormatVersion\|Resources:" "$files" 2>/dev/null; then
		if command -v cfn-lint >/dev/null 2>&1; then
			cfn_lint_output=$(cfn-lint "$files" 2>&1)
			cfn_lint_exit_code=$?
		fi
	fi

	debug_timer "Completed CloudFormation lint"
fi

has_issues=false

formatting_applied=false
if [[ $fmt_output == *"Formatted"* ]]; then
	formatting_applied=true
fi

if [[ $qlty_available == true ]]; then
	if [[ $check_output != *"No issues"* ]] || [[ $check_exit_code -ne 0 ]]; then
		has_issues=true
	fi
fi

if [[ $ruff_exit_code -ne 0 ]] || [[ $pyright_exit_code -ne 0 ]]; then
	has_issues=true
fi

if [[ $eslint_exit_code -ne 0 ]] || [[ $tsc_exit_code -ne 0 ]] || [[ $awslint_exit_code -ne 0 ]]; then
	has_issues=true
fi

if [[ $cfn_lint_exit_code -ne 0 ]]; then
	has_issues=true
fi

if [[ $has_issues == true ]]; then
	echo -e "${RED}🛑 STOP - Issues found in: $files${NC}" >&2
	echo -e "${RED}The following MUST BE FIXED:${NC}" >&2
	echo "" >&2

	if [[ $qlty_available == true ]] && [[ $check_output != *"No issues"* ]]; then
		issue_lines=$(echo "$check_output" | grep -E "^\s*[0-9]+:[0-9]+\s+|high\s+|medium\s+|low\s+" | head -3)
		remaining_issues=$(echo "$check_output" | grep -c "high\|medium\|low" 2>/dev/null || echo "0")

		if ! [[ $remaining_issues =~ ^[0-9]+$ ]]; then
			remaining_issues=0
		fi

		echo "🔍 QLTY Issues: ($remaining_issues remaining)" >&2

		if [[ -n $issue_lines ]]; then
			echo "$issue_lines" >&2
			if [[ $remaining_issues -gt 3 ]]; then
				echo "... and $((remaining_issues - 3)) more issues" >&2
			fi
		else
			echo "$check_output" | head -5 >&2
		fi
		echo "" >&2
	fi

	if [[ $ruff_exit_code -ne 0 ]] && [[ -n $ruff_output ]]; then
		echo "🔍 Ruff Issues:" >&2
		echo "$ruff_output" | head -5 >&2
		echo "" >&2
	fi

	if [[ $pyright_exit_code -ne 0 ]] && [[ -n $pyright_output ]]; then
		echo "🔍 Pyright Issues:" >&2
		echo "$pyright_output" | grep -E "error|warning" | head -5 >&2
		echo "" >&2
	fi

	if [[ $eslint_exit_code -ne 0 ]] && [[ -n $eslint_output ]]; then
		echo "🔍 ESLint Issues:" >&2
		echo "$eslint_output" | head -5 >&2
		echo "" >&2
	fi

	if [[ $tsc_exit_code -ne 0 ]] && [[ -n $tsc_output ]]; then
		echo "🔍 TypeScript Issues:" >&2
		echo "$tsc_output" | head -5 >&2
		echo "" >&2
	fi

	if [[ $awslint_exit_code -ne 0 ]] && [[ -n $awslint_output ]]; then
		echo "🔍 AWS CDK Lint Issues:" >&2
		echo "$awslint_output" | grep -E "error|warning" | head -5 >&2
		echo "" >&2
	fi

	if [[ $cfn_lint_exit_code -ne 0 ]] && [[ -n $cfn_lint_output ]]; then
		echo "🔍 CloudFormation Lint Issues:" >&2
		echo "$cfn_lint_output" | head -10 >&2
		echo "" >&2
	fi

	echo -e "${RED}Fix all issues above before continuing${NC}" >&2
	exit 1
else
	tools_used=()
	if [[ $ruff_format_applied == true ]]; then
		tools_used+=("Ruff")
	fi
	if [[ $prettier_format_applied == true ]]; then
		tools_used+=("Prettier")
	fi
	if [[ $eslint_format_applied == true ]]; then
		tools_used+=("ESLint")
	fi
	if [[ $terraform_fmt_applied == true ]]; then
		tools_used+=("Terraform")
	fi
	if [[ $formatting_applied == true ]]; then
		tools_used+=("QLTY")
	fi

	if [[ ${#tools_used[@]} -gt 0 ]]; then
		tools_str=$(
			IFS="+"
			echo "${tools_used[*]}"
		)
		echo -e "${GREEN}✅ $tools_str formatted $files. Code quality good. Continue${NC}" >&2
	else
		echo -e "${GREEN}✅ Code quality good for $files. Continue${NC}" >&2
	fi
	debug_timer "Script completed successfully"
	exit 0
fi
