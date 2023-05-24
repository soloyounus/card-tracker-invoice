(function ($, w, SELECTOR) {
  $(window).on('invoicer:jobs:init', initJobs);
  $(window).on('invoicer:jobs:enqueue', addJob);
  $(window).on('invoicer:jobs:status', updateJobStatus);

  function initJobs(event, { jobs }) {
    $('tbody', SELECTOR.status).html('');

    jobs.forEach((x) => {
      addJob(null, x);
    });
  }

  function addJob(event, { jobId, args, status }) {
    const $node = $(getJobRowHtml(arguments[1]));

    $('tbody', SELECTOR.status).append($node);
  }

  function updateJobStatus(event, { jobId, status }) {
    const $job = $(`[data-id=${jobId}]`, SELECTOR.status);

    switch (status) {
      case 'empty':
        $('[data-status]', $job).text('No orders found');
        break;
      case 'fail':
        $('[data-status]', $job).text('Unknown failure');
        break;
      case 'complete':
        $('[data-status]', $job).html(getDownloadLink(arguments[1]));
        break;
      default:
        $('[data-status]', $job).text(status);
        break;
    }
  }

  function deleteJob(event, { jobId }) {
    const $job = $(`[data-id=${jobId}]`, SELECTOR.status);

    $job.remove();
  }

  function getJobRowHtml({ jobId }) {
    return `<tr data-id="${jobId}">${getJobRowColumnsHtml(arguments[0])}</tr>`;
  }

  function getJobRowColumnsHtml({ args, status }) {
    const { num, start, end, aname, commissions_only } = args;
    var name = aname;

    if (aname === 'All Partners') {
      name += commissions_only ? ' (commissions)' : ' (orders)';
    }

    return `<td data-num>${num}</td>
      <td data-aname>${name}</td>
      <td data-date>${start}</td>
      <td>
        <span data-status>${status}</span>
      </td>
    `;
  }

  function getDownloadLink({ jobId }) {
    return `<a download href="/reports/${jobId}">Download</a>`;
  }
})(jQuery, window, {
  form: '#generateInvoiceForm',
  status: '#jobStatus',
});
