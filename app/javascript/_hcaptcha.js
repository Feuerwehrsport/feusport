const initHCaptcha = function () {
  const captchaDiv = document.querySelector('[data-controller=hcaptcha]');
  if (!captchaDiv) return;

  if (window.hcaptcha) {
    hcaptcha.render(captchaDiv, { sitekey: captchaDiv.dataset.sitekey });
  } else {
    setTimeout(() => {
      initHCaptcha();
    }, 200);
  }
};
onVisit(function () {
  setTimeout(() => {
    initHCaptcha();
  }, 200);
});
