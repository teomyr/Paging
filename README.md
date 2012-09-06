For players who want to get the most out of the default action bar, the **Paging** addon automatically switches the primary action buttons to 10 different pages, based on customizable macro modifiers. You can, for example, change to different bars based on the target unit's reaction, or page using the Shift and CTRL keys to access more different abilities with the same set of keyboard buttons.

Since Paging uses the default Blizzard action bar, it is quick to set up ‒ there are no extra bars to fiddle around on screen, and it stays out of the way when paging is not necessary. This makes the addon ideal for players who do not want to spend time on configuring a full-blown action bar replacement, but who desire the automatic paging feature that some of them have to offer.

Quick facts
===========

* Automatic switching between action bar pages
* Uses the same logic as macro conditionals (`[harm]`, `[mod:shift]`, etc.)
* Can override stance-based paging, if desired
* Profile support (can also set default profiles per realm or class)
* Deals with keybindings automatically
* No dependencies, requires only the default Blizzard action bar

How it works
============

Paging changes the action bar so that it switches the bar number depending on the current situation. You specify which page to use using a set of macro conditionals. These conditionals use the same syntax you know from e.g. the `/cast` command, however with page numbers instead of spell names. Like this:

`[mod:shift] 6; [mod:ctrl] 5;`

(This is the example profile supplied with Paging. You can use the profile selection menu in Paging's addon settings to copy it to your current profile.)

The meaning of this setting is: "While the shift key is pressed down, choose action page 6. While the control key is pressed down, choose action page 5. In all other cases, use the default action bar."
Action pages 6 and 5 are the extra bars at the lower left and lower right, respectively. You can then access their abilities using Shift-1, Shift-2, … and CTRL-1, CTRL-2, …

This was just a trivial example of Paging's functionality. While this behaviour could be replicated using key bindings, macro conditionals are far more powerful than that. They can, for example, differentiate between allied and enemy units:

`[help] [mod:alt] 2;`

Using this selector, whenever you target a friendly unit or press ALT, the action bar switches to the second page, where you can place your beneficial spells. The `[mod:alt]` is there to play nicely with the ALT selfcast offered by the default UI.

While Paging overrides your default action bar page, the page indicator to the right lights up. If you omit the page number in your selector, Paging switches back to the default action page.

Examples
========

Shadow Priest: Do not switch to a separate action bar while in Shadowform, keep the default one

    [stance:1] 1;

Shadow Priest: Same as above, but with helpful spells/self-casting on bar 2

    [help] [mod:alt] 2; [stance:1] 1;

Druid: Have healing spells on bar 1 with ALT self-casting, and show damage spells from bar 2 while not shapeshifted and targeting an enemy

    [mod:alt] 1; [nostance, harm] 2;

Switch to two extra bars using SHIFT and CTRL, and also have a separate bar for friendly units and self-casting

    [help] [mod:alt] 2; [mod:shift] 6; [mod:ctrl] 5;

More action bar madness: Same as above, but now has two bars for friendly units/selfcasting toggled with SHIFT

    [mod:alt-shift] [mod:shift, help] 8; [mod:shift] 6; [mod:ctrl] 5; [mod:alt] [help] 2;

Reference
=========

For a list of macro conditionals, please have a look at [Wowpedia: Macro conditionals](http://www.wowpedia.org/Macro_conditionals).

The mapping of action bar page numbers is as follows (adapted from [Wowpedia: Action Bar](http://www.wowpedia.org/Action_Bar) and [Wowpedia: Stance](http://www.wowpedia.org/Stance)):

1. Primary Action Bar
2. Primary Action Bar
3. Right Bar
4. Right Bar 2
5. Bottom Right Bar
6. Bottom Left Bar
7. *Druid:* Cat Form (Stance 3), *Rogue:* Stealth (Stance 1), *Priest:* Shadowform (Stance 1)
8. Unused
9. *Druid:* Bear Form (Stance 1)
10. *Druid:* Moonkin Form (Stance 5)

For the classes not mentioned in the list, pages 7 to 10 are unused and free to be used.

*You do not have to write selectors for the default stance-based paging* (and you shouldn't do that either). This means that e.g. if you're a druid, don't use selectors like `[stance:1] 9; [stance:3] 7; [stance:5] 10;` to get the usual stance bars ‒ the default behavior already does that for you, so you only have to let it fall back to an empty selector in that case.

Tips
====

You should always design your modifiers so that they fall back to the default action page if no conditional matches. This is what the semicolon at the end is for: if no page number is given, it resolves to "whatever Blizzard's unmodified action bar would show".
If you forget to do this, you get an interesting, but not usually desired effect where the bar remains in the switched state even after its selector no longer applies.

In the default configuration, Paging recognizes which modifier keys your selector uses and temporarily disables any key combination that could mask this modifier and prevent it from working. For example, if your action button 1 is bound to key "1" and your selector includes `[mod:ctrl]`, Paging will disable an existing key binding for CTRL-1 (which is normally bound to the pet bar). Using `[mod:alt-lshift]` will disable ALT-1, LShift-1, ALT-LShift-1, ALT-Shift-1 and Shift-1 (which is normally bound to manually switching to the first action bar). These changes are non-permanent and only affect key bindings involving your action buttons. However, if your key binding setup is more complex, you can of course choose to disable this automatic feature and handle such conflicts manually.

Normally, Paging disables itself when the default action bar would be overridden by a special bar, such as when in a vehicle, in a pet battle or while dominating another unit. The reason for this is that it might break unexpectedly if one's selector does not account for these special occasions: If a Shadow Priest were to use the `[stance:1] 1;` selector from the examples above, using Dominate Mind on an enemy creature would never bring up the dominated unit's actions. Paging therefore gives priority to these special bars.
If you want to tweak this behaviour, for example if you still want quick access to your own abilities while dominating some unit, you can disable this safety measure by incorporating any or all of the macro modifiers `overridebar`, `extrabar`, `possessbar` and `petbattle` in your selector with a lower priority.

Feedback
========

If you have any issues with the addon, feel free to report them in the [issue tracker](https://github.com/teomyr/Paging/issues) on GitHub. Alternatively, you can also leave comments on [WoWInterface](http://www.wowinterface.com/downloads/fileinfo.php?id=18229#comments).

Locales for the English, German and French language versions are included; localization help is greatly appreciated!

Beyond the Addon
================

If you find that you need more advanced features not offered by Paging, such as adding more action bars on screen, moving them or paging multiple bars at once, I suggest that you take a look at other action bar mods. [Bartender4](http://www.wowinterface.com/downloads/info11190-Bartender4.html), for example, is a customization powerhouse and has been one of my long-time favorite addons. You can re-use the same modifiers as in Paging, so the transition should be seamless ‒ but, as with any addon, keep in mind that additional features require you to spend more time configuring them.
