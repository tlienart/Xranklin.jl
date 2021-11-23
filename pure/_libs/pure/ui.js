(function (window, document) {
      function getElements() {
          return {
              menu_panel:  document.getElementById('layout-left-menu'),
              menu_burger: document.getElementById('menu-burger')
          };
      }
      function toggleClass(element, className) {
          var classes = element.className.split(/\s+/);
          var length = classes.length;
          var i = 0;
          for (; i < length; i++) {
              if (classes[i] === className) {
                  classes.splice(i, 1);
                  break;
              }
          }
          // The className is not found
          if (length === classes.length) {
              classes.push(className);
          }
          element.className = classes.join(' ');
      }
      function toggleAll() {
          var active = 'active';
          var elements = getElements();
          toggleClass(elements.menu_panel,   active);
          toggleClass(elements.menu_burger,  active);
      }
      function handleEvent(e) {
          var elements = getElements();
          if (e.target.id === elements.menu_burger.id) {
              toggleAll();
              e.preventDefault();
          } else if (elements.menu.className.indexOf('active') !== -1) {
              toggleAll();
          }
      }
      document.addEventListener('click', handleEvent);
  }(this, this.document));
