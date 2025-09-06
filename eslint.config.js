import { FlatCompat } from "@eslint/eslintrc";
import js from "@eslint/js";

const compat = new FlatCompat({
  recommendedConfig: js.configs.recommended
});

export default [
  js.configs.recommended,
  ...compat.config({
    extends: ["eslint:recommended"],
    rules: {
      // add custom rules here
    },
  }),
];
