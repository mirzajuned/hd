function copyToClipboard(element) {
  var tempInput = $("<input>");
  $("body").append(tempInput);
  tempInput.val($(element).text()).select();
  document.execCommand("copy");
  tempInput.remove();
}
