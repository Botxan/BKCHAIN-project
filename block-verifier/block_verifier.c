#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

// Function to check if a character is a valid hex digit
bool is_hex(char c) {
    return isxdigit(c);
}

// Function to check if a string contains only digits
bool is_number(const char *str) {
    while (*str) {
        if (!isdigit(*str)) return false;
        str++;
    }
    return true;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s file1 file2\n", argv[0]);
        return 1;
    }

    FILE *f1 = fopen(argv[1], "r");
    FILE *f2 = fopen(argv[2], "r");

    if (!f1 || !f2) {
        printf("Error opening files\n");
        if (f1) fclose(f1);
        if (f2) fclose(f2);
        return 1;
    }

    // Compare files content
    bool files_match = true;
    long pos = 0;
    int c1, c2;

    while ((c1 = fgetc(f1)) != EOF) {
        c2 = fgetc(f2);
        if (c2 == EOF || c1 != c2) {
            files_match = false;
            break;
        }
        pos++;
    }

    if (!files_match) {
        printf("Files don't match in their initial content\n");
        fclose(f1);
        fclose(f2);
        return 1;
    }

    // Check if we have an empty line after the matching content
    c2 = fgetc(f2);
    if (c2 != '\n') {
        printf("Second file doesn't have an empty line after matching content\n");
        fclose(f1);
        fclose(f2);
        return 1;
    }

    // Read the last line
    char line[1024];
    if (fgets(line, sizeof(line), f2) == NULL) {
        printf("Couldn't read the last line from file2\n");
        fclose(f1);
        fclose(f2);
        return 1;
    }

    // Remove trailing newline if present
    size_t len = strlen(line);
    if (len > 0 && line[len-1] == '\n') {
        line[len-1] = '\0';
        len--;
    }

    // Check pattern: 8 hex chars + space + 2 hex chars + space + number
    if (len < 13) { // Minimum length: 8 + 1 + 2 + 1 + 1 = 13 characters
        printf("Last line is too short\n");
        return 1;
    }

    // Check first 8 characters are hex
    for (int i = 0; i < 8; i++) {
        if (!is_hex(line[i])) {
            printf("First 8 characters must be hex digits\n");
            fclose(f1);
            fclose(f2);
            return 1;
        }
    }

    // Check space
    if (line[8] != ' ') {
        printf("Character 9 must be a space\n");
        fclose(f1);
        fclose(f2);
        return 1;
    }

    // Check next 2 characters are hex
    for (int i = 9; i < 11; i++) {
        if (!is_hex(line[i])) {
            printf("Characters 10-11 must be hex digits\n");
            fclose(f1);
            fclose(f2);
            return 1;
        }
    }

    // Check second space
    if (line[11] != ' ') {
        printf("Character 12 must be a space\n");
        fclose(f1);
        fclose(f2);
        return 1;
    }

    // Check remaining characters form a valid number
    if (!is_number(&line[12])) {
        printf("Characters after second space must form a valid number\n");
        fclose(f1);
        fclose(f2);
        return 1;
    }

    printf("Block is correct\n");
    fclose(f1);
    fclose(f2);
    return 0;
}
