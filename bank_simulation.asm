%macro print_text 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

%macro read_text 2
    mov eax, 3
    mov ebx, 0
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

%macro open_file 2
    mov eax, 5
    mov ebx, %1
    mov ecx, %2
    mov edx, 420
    int 0x80
    mov [fd], eax
%endmacro

%macro close_file 0
    mov eax, 6
    mov ebx, [fd]
    int 0x80
%endmacro

section .data
    bank_art db "   _       ____    _    _   _ _  __       _  ", 10 
             db "  | |     | __ )  / \  | \ | | |/ /      | | ", 10
             db " / __)    |  _ \ / _ \ |  \| | ' /      / __)", 10
             db " \__ \    | |_) / ___ \| |\  | . \      \__ \", 10
             db " (   /    |____/_/   \_\_| \_|_|\_\     (   /", 10
             db "  |_|                                    |_| ", 10
    bank_art_len equ $ - bank_art                      

    border db 10, "==================================================", 10
    border_len equ $ - border

    menu_art db "               _  _ ____ _  _ _  _ ", 10
             db "               |\/| |___ |\ | |  | ", 10
             db "               |  | |___ | \| |__| ", 10, 10
    menu_art_len equ $ - menu_art

    art_check db 10, "                     [ CHECK ]", 10
    art_check_len equ $ - art_check

    art_deposit db 10, "                    [ DEPOSIT ]", 10
    art_deposit_len equ $ - art_deposit

    art_withdraw db 10, "                    [ WITHDRAW ]", 10
    art_withdraw_len equ $ - art_withdraw

    art_transfer db 10, "                    [ TRANSFER ]", 10
    art_transfer_len equ $ - art_transfer

    art_exit db 10, "                      [ EXIT ]  ", 10
    art_exit_len equ $ - art_exit

    pin_prompt db "          Enter 4-digit PIN: "
    pin_prompt_len equ $ - pin_prompt
    
    pin_success db 10, "          ACCESS GRANTED.", 10, 10
    pin_success_len equ $ - pin_success
    
    pin_fail db 10, "          ACCESS DENIED. Terminating program.", 10
    pin_fail_len equ $ - pin_fail

    menu db "            1. Check Balance", 10
         db "            2. Deposit", 10
         db "            3. Withdraw", 10
         db "            4. Transfer Money", 10
         db "            5. Exit and Print Receipt", 10
         db "            Enter choice: "
    menu_len equ $ - menu

    msg_amt db "          Enter amount: Php "
    msg_amt_len equ $ - msg_amt
    
    msg_bankid db "          Enter 14-digit Bank ID: "
    msg_bankid_len equ $ - msg_bankid
    
    msg_bal db "          Current Balance: Php "
    msg_bal_len equ $ - msg_bal
    
    msg_success db 10, "          >>> Transaction Successful! <<<", 10, 10
    msg_success_len equ $ - msg_success
    
    msg_error db 10, "          >>> INSUFFICIENT FUNDS! <<<", 10, 10
    msg_error_len equ $ - msg_error

    msg_invalid_amount db 10, "          >>> INVALID AMOUNT! <<<", 10
                       db "          >>> Please enter a valid positive number <<<", 10, 10
    msg_invalid_amount_len equ $ - msg_invalid_amount

    msg_invalid_id db 10, "          >>> INVALID BANK ID! Must be 14 digits. <<<", 10, 10
    msg_invalid_id_len equ $ - msg_invalid_id
    
    msg_invalid db "          >>> Invalid choice. Try again. <<<", 10
    msg_invalid_len equ $ - msg_invalid
    
    msg_receipt db "         --- OFFICIAL RECEIPT ---", 10
    msg_receipt_len equ $ - msg_receipt
    
    msg_thank db 10, "          Thank you for banking with us!", 10, 10
    msg_thank_len equ $ - msg_thank

    history_file db "history.txt", 0
    receipt_file db "receipt.txt", 0

    log_check db "Checked Balance.", 10
    log_check_len equ $ - log_check
    log_dep db "Deposited: Php "
    log_dep_len equ $ - log_dep
    log_wd db "Withdrew: Php "
    log_wd_len equ $ - log_wd
    log_tr db "Transferred: Php "
    log_tr_len equ $ - log_tr
    log_to db " to Account: "
    log_to_len equ $ - log_to

    newline db 10

section .bss
    pin_input resb 10
    choice resb 10
    input_buf resb 20
    bank_id resb 20
    bank_id_len resd 1
    fd resd 1
    balance resd 1
    amount resd 1
    file_buf resb 2048
    num_str resb 12

section .text
    global _start

_start:
    print_text border, border_len
    print_text bank_art, bank_art_len
    print_text border, border_len

    print_text pin_prompt, pin_prompt_len
    read_text pin_input, 10

    mov al, [pin_input]
    cmp al, '1'
    jne denied
    mov al, [pin_input + 1]
    cmp al, '2'
    jne denied
    mov al, [pin_input + 2]
    cmp al, '3'
    jne denied
    mov al, [pin_input + 3]
    cmp al, '4'
    jne denied

    print_text pin_success, pin_success_len
    jmp menu_start

denied:
    print_text pin_fail, pin_fail_len
    mov eax, 1
    mov ebx, 1
    int 0x80

menu_start:
    call clear_history
    mov dword [balance], 10000

menu_loop:
    print_text border, border_len
    print_text menu_art, menu_art_len
    print_text menu, menu_len
    
    read_text choice, 10        ; <--- UPDATED: Read up to 10 bytes
    
    ; <--- UPDATED: Check if they typed exactly 1 char + Enter (2 bytes or 3 for CRLF)
    cmp eax, 2
    je valid_menu_input
    cmp eax, 3
    je valid_menu_input
    
    print_text msg_invalid, msg_invalid_len
    print_text border, border_len
    jmp menu_loop

valid_menu_input:
    mov al, [choice]
    cmp al, '1'
    je do_check
    cmp al, '2'
    je do_deposit
    cmp al, '3'
    je do_withdraw
    cmp al, '4'
    je do_transfer
    cmp al, '5'
    je exit_program

    print_text msg_invalid, msg_invalid_len
    print_text border, border_len
    jmp menu_loop

do_check:
    print_text art_check, art_check_len
    print_text msg_bal, msg_bal_len
    mov eax, [balance]
    call print_num
    print_text newline, 1
    
    mov ecx, log_check
    mov edx, log_check_len
    call write_history
    
    print_text border, border_len
    jmp menu_loop

do_deposit:
    print_text art_deposit, art_deposit_len
    print_text msg_amt, msg_amt_len
    call read_amount

    cmp dword [amount], -1
    je invalid_amount_input
    cmp dword [amount], 0
    jle invalid_amount_input

    mov eax, [balance]
    add eax, [amount]
    mov [balance], eax

    print_text msg_success, msg_success_len
    
    mov ecx, log_dep
    mov edx, log_dep_len
    call write_history
    mov eax, [amount]
    call log_number
    
    print_text border, border_len
    jmp menu_loop

do_withdraw:
    print_text art_withdraw, art_withdraw_len
    print_text msg_amt, msg_amt_len
    call read_amount

    cmp dword [amount], -1
    je invalid_amount_input
    cmp dword [amount], 0
    jle invalid_amount_input

    mov eax, [amount]
    cmp eax, [balance]
    jg insufficient_funds

    mov eax, [balance]
    sub eax, [amount]
    mov [balance], eax

    print_text msg_success, msg_success_len
    
    mov ecx, log_wd
    mov edx, log_wd_len
    call write_history
    mov eax, [amount]
    call log_number
    
    print_text border, border_len
    jmp menu_loop

do_transfer:
    print_text art_transfer, art_transfer_len
    print_text msg_amt, msg_amt_len
    call read_amount

    cmp dword [amount], -1
    je invalid_amount_input
    cmp dword [amount], 0
    jle invalid_amount_input

    mov eax, [amount]
    cmp eax, [balance]
    jg insufficient_funds

    print_text msg_bankid, msg_bankid_len
    read_text bank_id, 20
    
    cmp eax, 15
    jne invalid_bank_id

    mov ecx, 0
check_id_digits:
    cmp ecx, 14
    je valid_bank_id
    mov al, [bank_id + ecx]
    cmp al, '0'
    jl invalid_bank_id
    cmp al, '9'
    jg invalid_bank_id
    inc ecx
    jmp check_id_digits

invalid_bank_id:
    print_text msg_invalid_id, msg_invalid_id_len
    print_text border, border_len
    jmp menu_loop

invalid_amount_input:
    print_text msg_invalid_amount, msg_invalid_amount_len
    print_text border, border_len
    jmp menu_loop

valid_bank_id:
    mov dword [bank_id_len], 14 
    
    mov eax, [balance]
    sub eax, [amount]
    mov [balance], eax

    print_text msg_success, msg_success_len

    mov ecx, log_tr
    mov edx, log_tr_len
    call write_history
    mov eax, [amount]
    call log_number
    
    mov ecx, log_to
    mov edx, log_to_len
    call write_history
    
    mov ecx, bank_id
    mov edx, [bank_id_len]
    call write_history
    
    mov ecx, newline
    mov edx, 1
    call write_history
    
    print_text border, border_len
    jmp menu_loop

insufficient_funds:
    print_text msg_error, msg_error_len
    print_text border, border_len
    jmp menu_loop

exit_program:
    print_text art_exit, art_exit_len
    print_text msg_thank, msg_thank_len
    
    open_file receipt_file, 0x242

    mov eax, 4
    mov ebx, [fd]
    mov ecx, msg_receipt
    mov edx, msg_receipt_len
    int 0x80

    mov eax, 4
    mov ebx, [fd]
    mov ecx, msg_bal
    mov edx, msg_bal_len
    int 0x80

    mov eax, [balance]
    call format_num
    mov eax, 4
    mov ebx, [fd]
    mov ecx, esi
    int 0x80

    mov eax, 4
    mov ebx, [fd]
    mov ecx, newline
    mov edx, 1
    int 0x80

    close_file

    open_file receipt_file, 0

    mov eax, 3
    mov ebx, [fd]
    mov ecx, file_buf
    mov edx, 2048
    int 0x80

    mov edx, eax
    mov eax, 4
    mov ebx, 1
    mov ecx, file_buf
    int 0x80

    close_file

    mov eax, 1
    xor ebx, ebx
    int 0x80

clear_history:
    open_file history_file, 0x241
    close_file
    ret

read_amount:
    read_text input_buf, 20
    mov ecx, input_buf
    call text_to_num
    mov [amount], eax
    ret

write_history:
    push ecx
    push edx
    open_file history_file, 0x441

    pop edx
    pop ecx
    mov eax, 4
    mov ebx, [fd]
    int 0x80

    close_file
    ret

log_number:
    push eax
    open_file history_file, 0x441

    pop eax
    call format_num
    
    mov eax, 4
    mov ebx, [fd]
    mov ecx, esi
    int 0x80

    mov eax, 4
    mov ebx, [fd]
    mov ecx, newline
    mov edx, 1
    int 0x80

    close_file
    ret

text_to_num:
    mov eax, 0
    mov ebx, 0
convert_loop:
    mov bl, [ecx]
    cmp bl, 10
    je done_convert
    cmp bl, 13
    je done_convert
    cmp bl, 0
    je done_convert
    cmp bl, '0'
    jl error_convert
    cmp bl, '9'
    jg error_convert
    sub bl, '0'
    movzx ebx, bl
    imul eax, eax, 10
    add eax, ebx
    inc ecx
    jmp convert_loop
error_convert:
    mov eax, -1
done_convert:
    ret

format_num:
    mov edi, num_str + 11
    mov byte [edi], 0
    dec edi
    mov ebx, 10
format_loop:
    mov edx, 0
    div ebx
    add dl, '0'
    mov [edi], dl
    dec edi
    cmp eax, 0
    jne format_loop
    inc edi
    mov esi, edi
    mov edx, num_str + 11
    sub edx, esi
    ret

print_num:
    call format_num
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 0x80
    ret
