import js from "@eslint/js";
import nodePlugin from "eslint-plugin-n";
import securityPlugin from "eslint-plugin-security";
import importPlugin from "eslint-plugin-import";

export default [
  {
    ignores: ["node_modules/", "dist/", "coverage/"],
  },

  js.configs.recommended,

  nodePlugin.configs["flat/recommended"],
  securityPlugin.configs.recommended,

  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...nodePlugin.configs["flat/recommended"].globals,
      },
    },
    plugins: {
      import: importPlugin,
    },
    rules: {
      "semi": ["error", "always"],
      "quotes": ["error", "single"],
      "indent": ["error", 2],

      "n/exports-style": ["error", "module.exports"],
      "n/file-extension-in-import": ["error", "always"],
      "n/prefer-promises/fs": "error", 

      "security/detect-object-injection": "warn",
      "no-eval": "error",
      "no-implied-eval": "error",

      "no-console": "warn",
      "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
      "prefer-const": "error",
    },
  },
];