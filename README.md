# I18nliner

[<img src="https://secure.travis-ci.org/jenseng/i18nliner.png" />](http://travis-ci.org/jenseng/i18nliner)

yay readme-driven development!

## TODO

* accurate line numbers for errors in ERB w/ t-blocks (currently they
match pre-processed, not original source)
* helpful error when t-blocks are used incorrectly (need to output block, no
args allowed)
* rake tasks
  * make sure check task actually works
  * implement:
    * dump
    * diff
    * import
* moar specs

====

I18nliner is I18n made simple.

No .yml files. Inline defaults. Optional keys. Inferred interpolation values.
Wrappers and blocks, so your templates look template-y and your translations
stay HTML-free.

## TL;DR

I18nliner lets you do stuff like this:

    t "Ohai %{@user.name}, my default translation is right here in the code. " +
      "Inferred keys and placeholder values, oh my!"

and even this:

    <%= t do %>
      Hey <%= amigo %>!
      Although I am <%= link_to "linking to something", random_path %> and
      have some <strong>bold text</strong>, the translators will see
      <strong><em>absolutely no markup</em></strong> and will only have a
      single string to translate :o
    <% end %>

## Installation

Add the following to your Gemfile:

    gem 'i18nliner'

## Features

### No more en.yml

Instead of maintaining .yml files and doing stuff like this:

    I18n.t :account_page_title

Forget the .yml and just do:

    I18n.t :account_page_title, "My Account"

Regular I18n options follow the (optional) default translation, so you can do
the usual stuff (placeholders, etc.).

#### Okay, but don't the translators need en.yml?

Sure, but *you* don't need to write it. Just run:

    rake i18nliner:dump

This extracts all default translations from your codebase, merges them with any
other ones (from rails or pre-existing .yml files), and outputs them to
`config/locales/generated/en.yml` (or rather, `"#{I18n.default_locale}.yml"`).

### It's okay to lose your keys

Why waste time coming up with keys that are less descriptive than the default
translation? I18nliner makes keys optional, so you can just do this:

    I18n.t "My Account"

I18nliner will create a [unique key](CONFIG.md) based on the translation (e.g.
`:my_account`), so you don't have to.

This can actually be a **good thing**, because when the `en` changes, the key
changes, which means you know you need to get it retranslated (instead of
letting a now-inaccurate translation hang out indefinitely). Whether you want
to show "[ missing translation ]" or the `en` value in the meantime is up to
you.

### Inferred Interpolation Values

Interpolation values may be inferred by I18nliner if not provided. So long as
it's an instance variable or method (or chain), you don't need to specify its
value. So this:

    <p>
      <%= t "Hello, %{user}. This request was a %{request_method}.", 
            :user => @user.name,
            :request_method => request.method
      %>
    </p>

Can just be this:

    <p>
      <%= t "Hello, %{@user.name}. This request was a %{request.method}." %>
    </p>

Note that local variables cannot be inferred.

### Wrappers and Blocks

#### The Problem

Suppose you have something like this in your ERB:

    <p>
      You can <%= link_to "lead", new_discussion_path %> a new discussion or
      <%= link_to "join", discussion_search_path %> an existing one.
    </p>

You might try something like this:

    <p>
      <%= t("You can %{lead} a new discussion or %{join} an existing one.",
            :lead => link_to(t("lead"), new_discussion_path),
            :join => link_to(t("join"), discussion_search_path)).html_safe
      %>
    </p>

This is not great, because:

1. There are three strings to translate.
2. When translating the verbs, the translator has no context for where it's
   being used... Is "lead" a verb or a noun?
3. Translators have their hands somewhat tied as far as what is inside the
   links and what is not.

So you might try this instead:

    <p>
      <%= t :discussion_html,
            "You can <a href="%{lead_url}">lead</a> a new discussion or " +
            "<a href="%{join_url}">join</a> an existing one.",
            :lead_url => new_discussion_path,
            :join_url => discussion_search_path
      %>
    </p>

This isn't much better, because now you have HTML in your translations. If you
want to add a class to the link, you have to go update all the translations.
A translator could accidentally break your page (or worse, cross-site script
it).

So what do you do?

#### Wrappers

I18nliner lets you specify wrappers, so you can keep HTML out the translations,
while still just having a single string needing translation:

    <p>
      <%= t "You can *lead* a new discussion or **join** an existing one.",
            :wrappers => [
              link_to('\1', new_discussion_path),
              link_to('\1', discussion_search_path)
            ]
      %>
    </p>

Default delimiters are increasing numbers of asterisks, but you can specify
any string as a delimiter by using a hash rather than an array.

#### Blocks

But wait, there's more!

Perhaps you want your templates to look like, well, templates. Try this:

    <p>
      <%= t do %>
        Welcome to the internets, <%= user.name %>
      <% end %>
    </p>

Or even this:

    <p>
      <%= t do %>
        <b>Ohai <%= user.name %>,</b>
        you can <%= link_to "lead", new_discussion_path %> a new discussion or
        <%= link_to "join", discussion_search_path %> an existing one.
      <% end %>
    </p>

In case you're curious about the man behind the curtain, I18nliner adds an ERB
pre-processor that turns the second example into something like this right
before it hits ERB:

    <p>
      <%= t :some_unique_key,
            "*Ohai %{user_name}*, you can **lead** a new discussion or ***join*** an existing one.",
            :user_name => user.name,
            :wrappers => [
              '<b>\1</b>',
              link_to('\1', new_discussion_path),
              link_to('\1', discussion_search_path)
            ]
      %>
    </p>

In other words, it will infer wrappers from your (balanced) markup and
[`link_to` calls](INFERRED_WRAPPERS.md), and will create placeholders for any
other (inline) ERB expressions. ERB statements (e.g.
`<% if some_condition %>...`) and block expressions (e.g.
`<%= form_for @person do %>...`) are *not* supported within a block
translation. The only exception to this rule is nested translation
calls, e.g. this is totally fine:

    <%= t do %>
      Be sure to
      <a href="/account/" title="<%= t do %>Account Settings<% end %>">
        set up your account
      </a>.
    <% end %>

#### HTML Safety

I18nliner ensures translations, interpolated values, and wrappers all play
nicely (and safely) when it comes to HTML escaping. If any translation,
interpolated value, or wrapper is HTML-safe, everything else will be HTML-
escaped.

### Inline Pluralization Support

Pluralization can be tricky, but [I18n gives you some flexibility](http://guides.rubyonrails.org/i18n.html#pluralization).
I18nliner brings this inline with a default translation hash, e.g.

    t({:one => "There is one light!", :other => "There are %{count} lights!"},
      :count => picard.visible_lights.count)

Note that the :count interpolation value needs to be explicitly set when doing
pluralization.

If you just want to pluralize a single word, there's a shortcut:

    t "person", :count => users.count

This is equivalent to:

    t({:one => "1 person", :other => "%{count} people"},
      :count => users.count)

I18nliner uses the pluralize helper to determine the default one/other values,
so if your `I18n.default_locale` is something other than English, you may need
to [add some inflections](https://gist.github.com/838188).

## Rake Tasks

### i18nliner:check

Ensures that there are no problems with your translate calls (e.g. missing
interpolation values, reusing a key for a different translation, etc.). **Go
add this to your Jenkins/Travis tasks.**

### i18nliner:dump

Does an i18nliner:check, and then extracts all default translations from your
codebase, merges them with any other ones (from rails or pre-existing .yml
files), and outputs them to `config/locales/generated/en.yml`.

### i18nliner:diff

Does an i18nliner:dump and creates a diff from a previous one (path or git
commit hash). This is useful if you only want to see what has changed since a
previous release of your app.

### i18nliner:import

Imports a translated yml file. Ensures that all placeholders and wrappers are
present.

#### .i18nignore and more

By default, the check and dump tasks will look for inline translations in any
.rb or .erb files. You can tell it to always skip certain
files/directories/patterns by creating a .i18nignore file. The syntax is the
same as [.gitignore](http://www.kernel.org/pub/software/scm/git/docs/gitignore.html),
though it supports
[a few extra things](https://github.com/jenseng/globby#compatibility-notes).

If you only want to check a particular file/directory/pattern, you can set the
environment variable `ONLY` when you run the command, e.g.

    rake i18nliner:check ONLY=/app/**/user*

## Compatibility

I18nliner is backwards compatible with I18n, so you can add it to an
established (and already internationalized) Rails app. Your existing
translation calls, keys and yml files will still just work without
modification.

I18nliner requires at least Ruby 1.9.3 and Rails 3.

## What about JavaScript/Handlebars?

Coming soon. I18nliner was inspired by some [I18n extensions](https://github.com/instructure/canvas-lms/tree/master/lib/i18n_extraction)
I did in [Canvas-LMS](https://github.com/instructure/canvas-lms). While
it also has the JavaScript/Handlebars equivalents, they are tightly
coupled to Canvas-LMS and are written in Ruby. So basically we're talking
a full reimplementation in JavaScript using
[esprima](http://esprima.org/) instead of the [shameful, brittle, regexy hack](http://cdn.memegenerator.net/instances/400x/24091937.jpg)
that is js_extractor.

## License

Copyright (c) 2013 Jon Jensen, released under the MIT license
