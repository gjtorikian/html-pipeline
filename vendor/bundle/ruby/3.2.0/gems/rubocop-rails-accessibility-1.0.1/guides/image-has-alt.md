# RailsAccessibility/ImageHasAlt

## Rule Details

Images should have an alt prop with meaningful text or an empty string for decorative images.

## Resources

- [W3C WAI Images Tutorial](https://www.w3.org/WAI/tutorials/images/)
- [Primer: Alternative text for images](https://primer.style/design/accessibility/alternative-text-for-images)

## Examples
### **Incorrect** code for this rule 👎

```erb
<%= image_tag "spinners/octocat-spinner-16px.gif", size: "12x12" %>
```

### **Correct** code for this rule  👍

```erb
<!-- good -->
<%= image_tag "spinners/octocat-spinner-16px.gif", size: "12x12", alt: "GitHub Logo spinner" %>
```

```erb
<!-- also good -->
<%= image_tag "spinners/octocat-spinner-16px.gif", size: "12x12", alt: "" %>
```
