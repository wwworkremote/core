const avoPreset = require('../../tmp/avo/tailwind.preset.js')

module.exports = {
  presets: [avoPreset],
  content: [
    ...avoPreset.content,
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/avo/**/*.html.erb',
  ],
  theme: {
    extend: {
      colors: {
        // Force Dracula Pro dark theme across Avo's light mode classes
        white: '#22212C', // Dracula background
        black: '#F8F8F2', // Dracula foreground
        gray: {
          50: '#17161D',   // Dracula background darker
          100: '#22212C', // Dracula background
          200: '#454158', // Dracula surface (bg_light)
          300: '#504C67', // Dracula gray_light
          400: '#7970A9', // Dracula gray
          500: '#7970A9', // Dracula gray
          600: '#C6C6C2', // Dracula fg_dark
          700: '#F8F8F2', // Dracula foreground
          800: '#FFFFFF', // Dracula fg_light
          900: '#FFFFFF', // Dracula fg_light
        },
        red: {
          400: '#FF9580', // Dracula red
          500: '#FF9580',
          600: '#FF9580',
        },
        orange: {
          400: '#FFCA80', // Dracula orange
          500: '#FFCA80',
          600: '#FFCA80',
        },
        yellow: {
          400: '#FFFF80', // Dracula yellow
          500: '#FFFF80',
          600: '#FFFF80',
        },
        green: {
          400: '#8AFF80', // Dracula green
          500: '#8AFF80',
          600: '#8AFF80',
        },
        teal: {
          400: '#80FFEA', // Dracula cyan
          500: '#80FFEA',
          600: '#80FFEA',
        },
        blue: {
          400: '#80FFEA', // Dracula cyan
          500: '#80FFEA',
          600: '#80FFEA',
        },
        indigo: {
          400: '#9580FF', // Dracula purple
          500: '#9580FF',
          600: '#9580FF',
        },
        violet: {
          400: '#9580FF', // Dracula purple
          500: '#9580FF',
          600: '#9580FF',
        },
        purple: {
          400: '#FF80BF', // Dracula pink
          500: '#FF80BF',
          600: '#FF80BF',
        },
        pink: {
          400: '#FF80BF', // Dracula pink
          500: '#FF80BF',
          600: '#FF80BF',
        }
      }
    }
  }
}
