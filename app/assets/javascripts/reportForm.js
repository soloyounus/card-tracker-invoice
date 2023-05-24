/**
 *
 * @param {jQuery} $
 */
(function ($) {
  const cfg = {
    formSelector: '#generateInvoiceForm',
    reportTypeSelector: '#partner_id',
    endDateFieldsSelector: '#end_date_fields',
    errorSelector: '.form-group > .form-error',
  };

  $(init);

  function init() {
    const form = $(cfg.formSelector);
    const formError = $(cfg.errorSelector, form);
    const reportType = $(cfg.reportTypeSelector, form);
    const endDateFields = $(cfg.endDateFieldsSelector, form);

    if (form.length) {
      setEndDateVisibility(reportType.val(), endDateFields);

      form.on('ajax:error', (_ele, response) =>
        onFormError(response, formError),
      );
      form.on('submit change', () => {
        displayError('', formError);
      });
      reportType.on('change', (event) => {
        setEndDateVisibility(event.target.value, endDateFields);
      });
    }
  }

  function setEndDateVisibility(reportTypeValue, fieldsElement) {
    if (reportTypeValue === '-2' || reportTypeValue === '-1') {
      fieldsElement.removeClass('hidden');
    } else {
      fieldsElement.addClass('hidden');
    }
  }

  function onFormError(xhrResponse, errorElement) {
    if (xhrResponse && xhrResponse.responseJSON) {
      const res = xhrResponse.responseJSON;

      if (res.error) {
        displayError(res.error, errorElement);
      }
    }
  }

  function displayError(message, errorElement) {
    if (message) {
      errorElement.text(`Submit Error: ${message}`);
      errorElement.removeClass('hidden');
    } else {
      errorElement.text('');
      errorElement.addClass('hidden');
    }
  }
})(jQuery);
