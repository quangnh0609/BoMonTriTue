(function () {
    'use strict';
    if (window.NativeNumberInputs) return;
    function isNumeric(field) {
        return field && field.tagName === 'INPUT' && field.inputMode === 'decimal' &&
            !field.readOnly && !field.disabled && !field.hasAttribute('data-line-picker');
    }
    function selectValue(event) {
        const field = event.target;
        if (!isNumeric(field)) return;
        field.select();
        // Mobile browsers can move the caret after their default tap handling.
        setTimeout(function () {
            if (document.activeElement === field && isNumeric(field)) field.select();
        }, 0);
    }
    document.addEventListener('focusin', selectValue);
    document.addEventListener('click', selectValue);
    window.NativeNumberInputs = true;
})();
