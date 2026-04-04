const js = require("@eslint/js");
const globals = require("globals");

module.exports = [
  js.configs.recommended,
  {
    ignores: ["node_modules/**"], // Tell ESLint to ignore downloaded packages
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        ...globals.node, // Tells ESLint about 'process.env', '__dirname', etc.
      },
    },
    rules: {
      "no-unused-vars": ["warn", { 
        "argsIgnorePattern": "^_",
        "varsIgnorePattern": "^_",
        "caughtErrorsIgnorePattern": "^_"
      }], // Don't crash the pipeline just for an unused variable
    "no-console": "off", // Allow console.log() in your backend
    },
  },
];
