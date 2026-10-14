<%@ Control Language="C#" AutoEventWireup="true" %>

<!-- Custom Numeric Keyboard -->
<div id="customKeyboard" class="fixed bottom-0 left-0 right-0 bg-gray-100 border-t-2 border-gray-300 z-[90] hidden" style="box-shadow: 0 -4px 6px rgba(0,0,0,0.1);">
    <div class="grid grid-cols-4 gap-1 p-2 max-w-md mx-auto">
        <button type="button" class="keyboard-btn" data-value="7">7</button>
        <button type="button" class="keyboard-btn" data-value="8">8</button>
        <button type="button" class="keyboard-btn" data-value="9">9</button>
        <button type="button" class="keyboard-btn bg-red-100" data-value="backspace">
            <i class="fa-solid fa-delete-left"></i>
        </button>
        
        <button type="button" class="keyboard-btn" data-value="4">4</button>
        <button type="button" class="keyboard-btn" data-value="5">5</button>
        <button type="button" class="keyboard-btn" data-value="6">6</button>
        <button type="button" class="keyboard-btn bg-blue-100" data-value="-">−</button>
        
        <button type="button" class="keyboard-btn" data-value="1">1</button>
        <button type="button" class="keyboard-btn" data-value="2">2</button>
        <button type="button" class="keyboard-btn" data-value="3">3</button>
        <button type="button" class="keyboard-btn bg-blue-100" data-value=".">.</button>
        
        <button type="button" class="keyboard-btn col-span-2" data-value="0">0</button>
        <button type="button" class="keyboard-btn bg-gray-300" data-value="clear">C</button>
        <button type="button" class="keyboard-btn bg-green-200" data-value="done">✓</button>
    </div>
</div>

<style>
    html, body {
        touch-action: manipulation;
        -webkit-text-size-adjust: 100%;
        text-size-adjust: 100%;
    }

    .keyboard-btn {
        padding: 16px;
        font-size: 20px;
        font-weight: bold;
        background: white;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.1s;
        user-select: none;
        -webkit-user-select: none;
        -webkit-tap-highlight-color: transparent;
        touch-action: manipulation;
    }
    
    .keyboard-btn:active,
    .keyboard-btn.active-press {
        background: #e5e7eb;
        transform: scale(0.95);
    }
    
    .keyboard-btn:hover {
        background: #f3f4f6;
    }
    
    #customKeyboard {
        transition: transform 0.3s ease-out;
        touch-action: manipulation;
    }
    
    #customKeyboard.show {
        transform: translateY(0);
    }
    
    /* Highlight input đang active */
    input[data-numeric-keyboard].keyboard-active {
        outline: 3px solid #3b82f6 !important;
        outline-offset: 2px;
        background-color: #eff6ff !important;
    }

    @media screen and (max-width: 768px), (pointer: coarse) {
        input[data-numeric-keyboard] {
            font-size: 16px !important;
        }
    }
</style>

<script>
    // Custom Keyboard Handler
    if (typeof window.NumericKeyboard === 'undefined') {
        function lockMobileViewportScale() {
            let viewport = document.querySelector('meta[name="viewport"]');
            const content = 'width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
            if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                document.head.appendChild(viewport);
            }
            viewport.setAttribute('content', content);
        }

        function applyNoZoomInputStyle(input) {
            if (!input) return;
            if (window.matchMedia && window.matchMedia('(max-width: 768px), (pointer: coarse)').matches) {
                input.style.fontSize = '16px';
            }
        }

        function safePreventDefault(e) {
            if (e && e.cancelable) e.preventDefault();
        }

        lockMobileViewportScale();
        document.addEventListener('gesturestart', function(e) { safePreventDefault(e); }, { passive: false });
        document.addEventListener('gesturechange', function(e) { safePreventDefault(e); }, { passive: false });
        document.addEventListener('gestureend', function(e) { safePreventDefault(e); }, { passive: false });

        // Chặn double-tap zoom trên toàn bộ keyboard
        (function() {
            const kb = document.getElementById('customKeyboard');
            if (!kb) return;
            kb.addEventListener('dblclick', function(e) { safePreventDefault(e); }, { passive: false });
            let lastTouchEnd = 0;
            kb.addEventListener('touchend', function(e) {
                const now = Date.now();
                if (now - lastTouchEnd < 300) safePreventDefault(e);
                lastTouchEnd = now;
            }, { passive: false });
        })();
        window.NumericKeyboard = (function() {
            let activeInput = null;
            const keyboard = document.getElementById('customKeyboard');

            function safeSetSelection(input, start, end) {
                if (!input || typeof input.setSelectionRange !== 'function') return;
                try {
                    input.setSelectionRange(start, end);
                } catch (err) {
                    // Safari throws for some input states/types; editing should continue.
                }
            }

            function safeSelectAll(input) {
                if (!input) return;
                safeSetSelection(input, 0, input.value.length);
            }

            function getSelection(input) {
                if (!input) return { start: 0, end: 0, selected: false };
                if (input.hasAttribute('data-numeric-keyboard-select-all')) {
                    return { start: 0, end: input.value.length, selected: input.value.length > 0 };
                }
                try {
                    const start = input.selectionStart;
                    const end = input.selectionEnd;
                    if (typeof start === 'number' && typeof end === 'number') {
                        return { start: start, end: end, selected: start !== end };
                    }
                } catch (err) {
                }
                return { start: input.value.length, end: input.value.length, selected: false };
            }
            
            // Xử lý phím bàn phím — dùng pointerdown để không bị delay 300ms trên mobile
            document.addEventListener('pointerdown', function(e) {
                const btn = e.target.classList.contains('keyboard-btn') ? e.target : e.target.closest('.keyboard-btn');
                if (!btn) return;
                safePreventDefault(e);
                e.stopPropagation();

                if (!activeInput) return;

                const value = btn.getAttribute('data-value');

                // Kiểm tra xem text có đang được select không
                const selection = getSelection(activeInput);
                const isTextSelected = selection.selected;

                switch(value) {
                    case 'backspace':
                        if (isTextSelected) {
                            const start = selection.start;
                            const end = selection.end;
                            activeInput.value = activeInput.value.substring(0, start) + activeInput.value.substring(end);
                            safeSetSelection(activeInput, start, start);
                        } else {
                            activeInput.value = activeInput.value.slice(0, -1);
                        }
                        break;
                    case 'clear':
                        activeInput.value = '';
                        break;
                    case 'done':
                        if (activeInput.hasAttribute('data-money-keyboard')) {
                            formatMoneyValue(activeInput);
                        } else if (activeInput.hasAttribute('data-minute-mask')) {
                            // Minute fields keep their mm:ss mask.
                        } else {
                            formatDecimalValue(activeInput);
                        }
                        activeInput.blur();
                        hideKeyboard();
                        break;
                    case '-':
                        if (isTextSelected) {
                            activeInput.value = '-';
                            safeSetSelection(activeInput, 1, 1);
                        } else if (activeInput.value.length === 0) {
                            activeInput.value = '-';
                        } else if (!activeInput.value.startsWith('-')) {
                            activeInput.value = '-' + activeInput.value;
                        }
                        break;
                    case '.':
                        if (isTextSelected) {
                            activeInput.value = '.';
                            safeSetSelection(activeInput, 1, 1);
                        } else if (!activeInput.value.includes('.')) {
                            activeInput.value += '.';
                        }
                        break;
                    default:
                        if (isTextSelected) {
                            activeInput.value = value;
                            safeSetSelection(activeInput, 1, 1);
                        } else {
                            activeInput.value += value;
                        }
                }

                // Trigger input event
                activeInput.removeAttribute('data-numeric-keyboard-select-all');
                activeInput.dispatchEvent(new Event('input', { bubbles: true }));

                // Visual feedback
                btn.classList.add('active-press');
                setTimeout(function() { btn.classList.remove('active-press'); }, 100);
            });

            // Chặn click event trên keyboard để tránh xử lý 2 lần
            document.addEventListener('click', function(e) {
                if (e.target.classList.contains('keyboard-btn') || e.target.closest('.keyboard-btn')) {
                    safePreventDefault(e);
                    e.stopPropagation();
                }
            });
            
            // Format decimal value function (dùng cho ucAddMatch - số thập phân)
            function formatDecimalValue(input) {
                if (!input) return;
                
                let val = input.value.trim();
                if (val === '' || val === '-') {
                    return;
                }
                
                // Loại bỏ ký tự không phải số, dấu chấm, dấu trừ
                val = val.replace(/[^\d.-]/g, '');
                
                // Parse thành số
                let num = parseFloat(val);
                
                // Nếu không phải số hợp lệ, xóa
                if (isNaN(num)) {
                    input.value = '';
                    return;
                }
                
                // Format thành ##0.00
                input.value = num.toFixed(2);
            }
            
            // Format money integer value (dùng cho tiền cược - số nguyên, dấu cách)
            function formatMoneyValue(input) {
                if (!input) return;
                let val = input.value.replace(/\s/g, '').replace(/[^\d]/g, '');
                const num = parseInt(val) || 0;
                input.value = num === 0 ? '0' : num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
            }
            
            function getKeyboardModalContent(input) {
                if (!input) return null;
                return input.closest('#modalChampionFormContent') ||
                       input.closest('#modalFormContent') ||
                       input.closest('#esportFormContent') ||
                       input.closest('#erBody');
            }

            function shouldProxyPointer(input) {
                return !!(input && (input.closest('#esportFormContent') || input.closest('#erBody')));
            }

            function installPointerProxy(input, activate) {
                if (!shouldProxyPointer(input) || input.hasAttribute('data-numeric-keyboard-proxy')) return;
                const proxy = input.parentElement || input;
                input.setAttribute('data-numeric-keyboard-proxy', 'true');
                input.setAttribute('tabindex', '-1');
                input.style.pointerEvents = 'none';
                proxy.style.cursor = 'pointer';
                proxy.addEventListener('touchstart', activate, { passive: false });
                proxy.addEventListener('pointerdown', function(e) {
                    if (e.pointerType === 'mouse') return;
                    activate(e);
                });
                proxy.addEventListener('click', activate);
            }

            function showKeyboard(input) {
                // Xóa highlight từ input cũ
                if (activeInput && activeInput !== input) {
                    activeInput.classList.remove('keyboard-active');
                }
                
                activeInput = input;
                
                if (input) {
                    input.classList.add('keyboard-active');
                }
                
                if (keyboard) {
                    keyboard.classList.remove('hidden');
                    keyboard.classList.add('show');
                    
                    // Tìm modal content chứa input này
                    const modalContent = getKeyboardModalContent(input);
                    
                    if (modalContent) {
                        // Bước 1: set padding để tạo chỗ trống
                        modalContent.style.paddingBottom = '320px';
                    }
                    
                    // Bước 2: đợi keyboard hiện + layout reflow xong rồi mới scroll
                    setTimeout(function() {
                        if (!input) return;
                        const mc = getKeyboardModalContent(input);
                        if (mc) {
                            const inputRect = input.getBoundingClientRect();
                            const mcRect    = mc.getBoundingClientRect();
                            // Kiểm tra input có đang bị che bởi keyboard không (keyboard cao ~260px)
                            const keyboardHeight = 260;
                            const visibleBottom  = mcRect.bottom - keyboardHeight;
                            if (inputRect.bottom > visibleBottom || inputRect.top < mcRect.top) {
                                const inputTop  = inputRect.top - mcRect.top + mc.scrollTop;
                                const target    = inputTop - (mc.clientHeight - keyboardHeight) / 2;
                                mc.scrollTop = Math.max(0, target);
                            }
                        } else {
                            try {
                                input.scrollIntoView({ block: 'center' });
                            } catch (err) {
                                input.scrollIntoView();
                            }
                        }
                    }, 300);
                }
            }
            
            function hideKeyboard() {
                // Format trước khi đóng
                if (activeInput) {
                    if (activeInput.hasAttribute('data-money-keyboard')) {
                        formatMoneyValue(activeInput);
                    } else if (!activeInput.hasAttribute('data-minute-mask')) {
                        formatDecimalValue(activeInput);
                    }
                    activeInput.classList.remove('keyboard-active');
                }
                
                if (keyboard) {
                    keyboard.classList.remove('show');
                    setTimeout(function() {
                        keyboard.classList.add('hidden');
                    }, 300);
                    
                    // Xóa padding bottom khi đóng keyboard
                    const modalContent = getKeyboardModalContent(activeInput);
                    if (modalContent) {
                        modalContent.style.paddingBottom = '';
                    }
                }
                activeInput = null;
            }
            
            // Đóng keyboard khi click ra ngoài
            document.addEventListener('click', function(e) {
                // Không đóng nếu click vào keyboard hoặc input field
                if (e.target.closest('#customKeyboard') || 
                    e.target.closest('input[readonly][data-numeric-keyboard]')) {
                    return;
                }
                
                // Đóng keyboard nếu click ra ngoài
                if (activeInput) {
                    hideKeyboard();
                }
            }, true); // Use capture phase
            
            // Attach money input (integer, dấu cách) - dùng cho ucTicket và copybetting
            function attachMoneyInput(input) {
                if (!input) return;
                if (input.hasAttribute('data-numeric-keyboard-bound')) {
                    input.setAttribute('data-money-keyboard', 'true');
                    return;
                }
                
                input.setAttribute('readonly', 'readonly');
                input.setAttribute('data-numeric-keyboard', 'true');
                input.setAttribute('data-money-keyboard', 'true');
                input.setAttribute('data-numeric-keyboard-bound', 'true');
                input.setAttribute('inputmode', 'none');
                input.style.caretColor = 'transparent';
                applyNoZoomInputStyle(input);
                
                function activateInput(e) {
                    safePreventDefault(e);
                    showKeyboard(input);
                    if (!shouldProxyPointer(input)) {
                        setTimeout(function() {
                            safeSelectAll(input);
                        }, 10);
                    } else {
                        input.setAttribute('data-numeric-keyboard-select-all', 'true');
                    }
                }
                
                input.addEventListener('focus', activateInput);
                input.addEventListener('click', activateInput);
                
                input.addEventListener('touchstart', function(e) {
                    activateInput(e);
                }, { passive: false });

                input.addEventListener('pointerdown', function(e) {
                    if (e.pointerType === 'mouse') return;
                    activateInput(e);
                });
                installPointerProxy(input, activateInput);
            }
            
            // Public API
            return {
                show: showKeyboard,
                hide: hideKeyboard,
                attachMoneyInput: attachMoneyInput,
                attachToFields: function(fieldSelectors) {
                    fieldSelectors.forEach(function(selector) {
                        document.querySelectorAll(selector).forEach(function(field) {
                            if (!field || field.hasAttribute('data-numeric-keyboard-bound')) return;
                            // Chặn bàn phím mặc định
                            field.setAttribute('readonly', 'readonly');
                            field.setAttribute('data-numeric-keyboard', 'true');
                            field.setAttribute('data-numeric-keyboard-bound', 'true');
                            field.setAttribute('inputmode', 'none');
                            field.style.caretColor = 'transparent';
                            applyNoZoomInputStyle(field);
                            
                            function activateField(e) {
                                safePreventDefault(e);
                                showKeyboard(field);
                                // Select all text
                                if (!shouldProxyPointer(field)) {
                                    setTimeout(() => {
                                        safeSelectAll(field);
                                    }, 10);
                                } else {
                                    field.setAttribute('data-numeric-keyboard-select-all', 'true');
                                }
                            }
                            
                            field.addEventListener('focus', activateField);
                            field.addEventListener('click', activateField);
                            
                            // Prevent default touch behavior
                            field.addEventListener('touchstart', function(e) {
                                activateField(e);
                            }, { passive: false });

                            field.addEventListener('pointerdown', function(e) {
                                if (e.pointerType === 'mouse') return;
                                activateField(e);
                            });
                            installPointerProxy(field, activateField);
                        });
                    });
                }
            };
        })();
    }
</script>
