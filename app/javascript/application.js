// Entry point for the build script in your package.json
import * as bootstrap from 'bootstrap';
import '@hotwired/turbo-rails';
import EasyMDE from 'easymde';

import './_certificates';
import './_edit_assessment_requests';
import './_move_score_list_entries';
import './_team_suggestions';

document.addEventListener('turbo:load', () => {
  document.querySelectorAll('textarea.easymde-required').forEach((textarea) => {
    var editor = new EasyMDE({
      element: textarea,
      autoDownloadFontAwesome: false,
      spellChecker: false,
      status: false,
      toolbar: [
        'bold',
        'italic',
        'heading-3',
        '|',
        'unordered-list',
        'ordered-list',
        'link',
        '|',
        {
          name: 'tabelle',
          action: EasyMDE.drawTable,
          className: 'fa fa-table',
          title: 'Tabelle einfügen',
        },
        'horizontal-rule',
        '|',
        'preview',
        'side-by-side',
        'fullscreen',
        'guide',
      ],
    });
  });

  window.SocialShareButton = {
    openUrl: function (url, width = 640, height = 480) {
      var left, opt, top;
      left = screen.width / 2 - width / 2;
      top = screen.height * 0.3 - height / 2;
      opt = `width=${width},height=${height},left=${left},top=${top},menubar=no,status=no,location=no`;
      window.open(url, 'popup', opt);
      return false;
    },
    share: function (el) {
      var $parent, appkey, desc, ga, get_tumblr_extra, hashtags, img, site, title, tumblr_params, url, via, via_str, whatsapp_app_url;
      if (el.getAttribute === null) {
        el = document.querySelector(el);
      }
      site = el.getAttribute('data-site');
      appkey = el.getAttribute('data-appkey') || '';
      $parent = el.parentNode;
      title = encodeURIComponent(el.getAttribute('data-' + site + '-title') || $parent.getAttribute('data-title') || '');
      img = encodeURIComponent($parent.getAttribute('data-img') || '');
      url = encodeURIComponent($parent.getAttribute('data-url') || '');
      via = encodeURIComponent($parent.getAttribute('data-via') || '');
      desc = encodeURIComponent($parent.getAttribute('data-desc') || ' ');
      // tracking click events if google analytics enabled
      ga = window[window['GoogleAnalyticsObject'] || 'ga'];
      if (typeof ga === 'function') {
        ga('send', 'event', 'Social Share Button', 'click', site);
      }
      if (url.length === 0) {
        url = encodeURIComponent(location.href);
      }
      switch (site) {
        case 'email':
          location.href = `mailto:?subject=${title}&body=${url}`;
          break;
        case 'twitter':
          hashtags = encodeURIComponent(el.getAttribute('data-' + site + '-hashtags') || $parent.getAttribute('data-hashtags') || '');
          via_str = '';
          if (via.length > 0) {
            via_str = `&via=${via}`;
          }
          SocialShareButton.openUrl(`https://twitter.com/intent/tweet?url=${url}&text=${title}&hashtags=${hashtags}${via_str}`, 650, 300);
          break;
        case 'facebook':
          SocialShareButton.openUrl(`http://www.facebook.com/sharer/sharer.php?u=${url}`, 555, 400);
          break;
        case 'vkontakte':
          SocialShareButton.openUrl(`http://vk.com/share.php?url=${url}&title=${title}&image=${img}`);
          break;
        case 'telegram':
          SocialShareButton.openUrl(`https://telegram.me/share/url?text=${title}&url=${url}`);
          break;
        case 'whatsapp_app':
          whatsapp_app_url = `whatsapp://send?text=${title}%0A${url}`;
          window.open(whatsapp_app_url, '_top');
          break;
        case 'whatsapp_web':
          SocialShareButton.openUrl(`https://web.whatsapp.com/send?text=${title}%0A${url}`);
      }
      return false;
    },
  };
});
