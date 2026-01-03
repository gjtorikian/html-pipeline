# RailsAccessibility/NoRedundantImageAlt

## Rule Details

Alt prop should not contain `image` or `picture` as screen readers already announce the element as an image

## Resources

- [W3C WAI Images Tutorial](https://www.w3.org/WAI/tutorials/images/)
- [Primer: Alternative text for images](https://primer.style/design/accessibility/alternative-text-for-images)

## Examples
### **Incorrect** code for this rule 👎

```erb
<%= image_tag "cat.gif", size: "12x12", alt: "Picture of a cat" %>
```

### **Correct** code for this rule  👍

```erb
<!-- good -->
<%= image_tag "cat.gif", size: "12x12", alt: "A black cat" %>
```
