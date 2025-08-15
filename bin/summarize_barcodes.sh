#!/bin/bash
set -euo pipefail
set -x  # for debugging

# Arguments
pool_id=${1:?Missing pool_id}
error_rate=${2:?Missing error_rate}
summary_file="${pool_id}_${error_rate}_barcode_report.csv"

# Initialize
declare -A barcode_counts
total_reads=0
unknown_reads=0
other_barcodes_reads=0

# Count reads per barcode
for file in *.fastq.gz; do
    barcode="${file%.fastq.gz}"

    # count reads safely
    reads=$(zcat "$file" 2>/dev/null | awk 'END{print NR/4}' 2>/dev/null || echo 0)

    if [[ "$barcode" == "unknown"* ]]; then
        unknown_reads=$((unknown_reads + reads))
    else
        barcode_counts["$barcode"]=$reads
        total_reads=$((total_reads + reads))
    fi
done

# Include unknown reads in total
total_reads=$((total_reads + unknown_reads))

# Compute average reads per barcode (excluding unknown)
num_barcodes=${#barcode_counts[@]}
avg_reads=0
if (( num_barcodes > 0 )); then
    sum_reads=0
    for r in "${barcode_counts[@]}"; do
        sum_reads=$((sum_reads + r))
    done
    avg_reads=$((sum_reads / num_barcodes))
fi

# Threshold = 20% of average
threshold=$((avg_reads / 5))

# Categorize barcodes based on threshold
declare -A final_barcode_counts
for barcode in "${!barcode_counts[@]}"; do
    count=${barcode_counts[$barcode]}
    if (( count < threshold )); then
        other_barcodes_reads=$((other_barcodes_reads + count))
    else
        final_barcode_counts["$barcode"]=$count
    fi
done

# Calculate percentages safely
unknown_pct=$(awk -v u="$unknown_reads" -v t="$total_reads" 'BEGIN{printf "%.2f", (t>0)?u*100/t:0}')
other_barcodes_pct=$(awk -v o="$other_barcodes_reads" -v t="$total_reads" 'BEGIN{printf "%.2f", (t>0)?o*100/t:0}')

# Total demuxed reads (known barcodes above threshold)
demuxed_reads=0
for count in "${final_barcode_counts[@]}"; do
    demuxed_reads=$((demuxed_reads + count))
done

demux_rate=$(awk -v d="$demuxed_reads" -v t="$total_reads" 'BEGIN{printf "%.2f", (t>0)?d*100/t:0}')

# Generate CSV report
{
    echo "Total Reads:,${total_reads}"
    echo "Unknown Reads:,${unknown_reads},${unknown_pct}%"
    echo "Other Barcodes (count < 20% of avg):,${other_barcodes_reads},${other_barcodes_pct}%"
    echo "Total Demuxed Reads:,${demuxed_reads},Demux Rate:,${demux_rate}%"
    echo ""
    echo "Barcode,Read_Count,Percent_of_Total"

    # Known barcodes sorted
    for barcode in $(printf '%s\n' "${!final_barcode_counts[@]}" | sort -V); do
        count=${final_barcode_counts[$barcode]}
        pct=$(awk -v c="$count" -v t="$total_reads" 'BEGIN{printf "%.2f", (t>0)?c*100/t:0}')
        echo "${barcode},${count},${pct}"
    done

    # Other barcodes
    [[ $other_barcodes_reads -gt 0 ]] && echo "other_barcodes,${other_barcodes_reads},${other_barcodes_pct}"
    # Unknown
    [[ $unknown_reads -gt 0 ]] && echo "unknown.merged,${unknown_reads},${unknown_pct}"
} > "$summary_file"

echo "Successfully generated: $summary_file"

