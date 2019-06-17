

const init = () => {
  let bodyClasses = new Set();
  bodyClasses.add('sidebar-fixed');
  bodyClasses.add('topnav-fixed');
  bodyClasses.add('dashboard');

  function determineSidebar() {
    if (window.innerWidth < 992) {
      bodyClasses.add('sidebar-float');
    } else {
      bodyClasses.delete('sidebar-float');
    }
    document.body.className = Array.from(bodyClasses).join(" ");
  }

  window.addEventListener('load', determineSidebar);
  window.addEventListener('resize', determineSidebar);
};

export default init;
