// Force Avo into dark mode to render the Dracula Pro theme
document.documentElement.classList.add('dark');
document.documentElement.classList.remove('light');
localStorage.theme = 'dark';

document.addEventListener('turbo:load', () => {
  document.documentElement.classList.add('dark');
  document.documentElement.classList.remove('light');
  localStorage.theme = 'dark';
});
