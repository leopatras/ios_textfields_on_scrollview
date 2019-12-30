# ios_textfields_on_scrollview
show cases how to wire UITextField(s) on an UIScrollView
It is  demonstrated how to wire UITextFields to get the wanted
"scroll into view" behavior on a UIScrollView when tapping/focusing fields.
The UITextField scrolls into view upon  [MyTextField becomeFirstResponder]
 if the keyboard appears/disappears, UIScrollViews contentInset.bottom is updated.

In addition a custom inputAccessoryView is demonstrated to jump to the prev/next field (like in WkWebView) and close the keyboard.
