# RailsAccessibility/NoPositiveTabindex

## Rule Details

Positive tabindex is error-prone and often inaccessible.

## Resources

- [F44: Failure of Success Criterion 2.4.3 due to using tabindex to create a tab order that does not preserve meaning and operability](https://www.w3.org/TR/WCAG20-TECHS/F44.html)
- [Deque University: Avoid Using Tabindex with Positive Numbers](https://dequeuniversity.com/tips/tabindex-positive-numbers)

## Examples
### **Incorrect** code for this rule 👎

```erb
<%= button_tag "Continue", :tabindex => 3 %>
```

### **Correct** code for this rule  👍

```erb
<!-- good -->
<%= button_tag "Continue", :tabindex => -1 %>
```
