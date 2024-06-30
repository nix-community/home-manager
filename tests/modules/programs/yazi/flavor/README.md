<div align="center">
  <img src="https://github.com/sxyazi/yazi/blob/main/assets/logo.png?raw=true" alt="Yazi logo" width="20%">
</div>

<h3 align="center">
	Example Flavor for <a href="https://github.com/sxyazi/yazi">Yazi</a>
</h3>

## Cooking up a new flavor

> [!NOTE]
> Please remove this section from your README before publishing.

1. [x] Fork this repository and rename it to `your-flavor-name.yazi`.
2. [ ] Copy the **parts you need to customize** from the [default theme.toml](https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/theme.toml) as `./flavor.toml`, and change them to meet your preferences.
3. [ ] Find a `.tmTheme` file on GitHub that matches the color of your flavor, copy it and it's license file as `./tmtheme.xml`, and `LICENSE-tmtheme`.
4. [ ] Modify the content and preview image in the README to fit your flavor.

## 👀 Preview

<img src="preview.png" width="600" />

## 🎨 Installation

<!-- Please replace "username/example.yazi" with your repository name. -->

```bash
# Linux/macOS
git clone https://github.com/username/example.yazi.git ~/.config/yazi/flavors/example.yazi

# Windows
git clone https://github.com/username/example.yazi.git %AppData%\yazi\config\flavors\example.yazi
```

## ⚙️ Usage

Add the these lines to your `theme.toml` configuration file to use it:

<!-- Please replace "example" with your flavor name. -->

```toml
[flavor]
use = "example"
```

## 📜 License

The flavor is MIT-licensed, and the included tmTheme is also MIT-licensed.

Check the [LICENSE](LICENSE) and [LICENSE-tmtheme](LICENSE-tmtheme) file for more details.
