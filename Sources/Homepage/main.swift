import Foundation
import Publish
import Plot
import ShellOut
import Ink

// This type acts as the configuration for your website.
struct Homepage: Website {

    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case apps
        case blog
    }

    struct AppMetadata: WebsiteItemMetadata {
        var atfLink: String?
        var iasLink: String?
        var masLink: String?
        var appleID: Int?
        var mastodonLink: String?
    }

    struct ItemMetadata: WebsiteItemMetadata {
        var app: AppMetadata?
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://hans.coffee")!
    var name = "Hans Schülein"
    var description = "Hans Schülein"
    var language: Language { .english }
    var favicon: Favicon? = Favicon(path: "/icon.png", type: "image/png")
    var imagePath: Path? = "/icon.svg"
}

public enum MainElementDefinition: ElementDefinition { public static var wrapper = Node.main }
public typealias Main = ElementComponent<MainElementDefinition>
public enum AsideElementDefinition: ElementDefinition { public static var wrapper = Node.aside }
public typealias Aside = ElementComponent<AsideElementDefinition>
public enum SectionElementDefinition: ElementDefinition { public static var wrapper = Node.section }
public typealias HTMLSection = ElementComponent<SectionElementDefinition>


let homepage = Homepage()

func fixText(for html: String) -> String {
    return html
        .replacingOccurrences(of: #"LaTeX(?![^<>]*")"#, with: "<span class=\"latex\">L<sup>a</sup>T<sub>e</sub>X</span>", options: .regularExpression)
        .replacing(try! Regex(#"\^([^\s"]+)\^(?!\S*")"#), with: { match in
            "<abbr><span class='real-caps'>\("\(match[1].value!)".uppercased())</span><span class='small-caps' hidden>\(match[1].value!)</span></abbr>"
        })
}

let plugins: [Plugin<Homepage>] = [
    Plugin(name: "Fix Markdown") { context in
        context.markdownParser.addModifier(Modifier(target: .images) { html, markdown in
                let alt = try! Regex<(Substring, Substring)>(#"<img .*alt="((?>\\"|[^"])*)".*>"#).firstMatch(in: html)?.1
                if let alt, alt.contains("|") {
                    // Replace images with subtitle with an actual figure
                    return html.replacing(try! Regex(#"(<img [^>]*alt=\")((?>[^"]|\\\"])+)("[^>]*>)"#), with: { match in
                            let components = alt.split(separator: "|", maxSplits: 1)
                            return "<figure>\(match[1].value!)\(components[0])\(match[3].value!)<figcaption>\(fixText(for: String(components[1])))</figcaption></figure>"
                        })
                } else {
                    // Just keep normal image
                    return html
                }
            })
        context.markdownParser.addModifier(Modifier(target: .paragraphs) { html, markdown in
                return fixText(for: html)
            })
    }
]

let deploymentMethod: DeploymentMethod<Homepage> = DeploymentMethod(name: "strato", body: { context in
    if let folder = try? context.outputFolder(at: ".") {
        try shellOut(to: "rsync -avz --chmod=ugo+r --delete --exclude \".*\" ./* www.hans.coffee@ssh.strato.de:~/hans.coffee", at: folder.path)
    } else {
        print("Output folder not accessible")
    }
})

try homepage.publish(
    at: nil,
    using: [
            .group(plugins.map(PublishingStep.installPlugin)),
            .optional(.copyResources()),
            .addMarkdownFiles(),
            .sortItems(by: \.date, order: .descending),
//        .group(additionalSteps),
        .generateHTML(withTheme: .main, indentation: nil),
            .generateRSSFeed(
            including: [.apps], // , .blog], // TODO add this back in once blog is active
            itemPredicate: Predicate(matcher: { $0.path.absoluteString.components(separatedBy: "/").count == 3 }),
            config: .default
        ),
            .generateSiteMap(indentedBy: nil),
            .unwrap(deploymentMethod, PublishingStep.deploy)
    ],
    file: #file
)

public extension Theme {
    /// The default "Foundation" theme that Publish ships with, a very
    /// basic theme mostly implemented for demonstration purposes.
    static var main: Self {
        Theme(
            htmlFactory: MainHTMLFactory(),
            resourcePaths: []
        )
    }
}

private struct MainHTMLFactory<Site: Website>: HTMLFactory {
    func makeIndexHTML(for index: Publish.Index, context: Publish.PublishingContext<Site>) throws -> Plot.HTML {
        return HTML(
                .lang(context.site.language),
            // .head(for: index, on: context.site),
            .head(
                    .encoding(.utf8),
//                    .siteName(context.site.name),
                .meta(.name("url"), .content(context.site.url(for: index).absoluteString)),
                    .element(named: "title", text: context.site.name),
                    .meta(.name("description"), .content(context.site.description)),
                //.twitterCardType(index.imagePath == nil ? .summary : .summaryLargeImage),
                .forEach(["/styles.css"], { .stylesheet($0) }),
                    .viewport(.accordingToDevice),
                    .unwrap(context.site.favicon, { .favicon($0) }),
                    .link(
                        .rel(HTMLLinkRelationship(rawValue: "apple-touch-icon")!),
                        .href("/apple-touch-icon.png")
                ),
                    .rssFeedLink(Path.defaultForRSSFeed.absoluteString, title: "Subscribe to \(context.site.name)"),
                    .unwrap(index.imagePath ?? context.site.imagePath, { path in
                    let url = context.site.url(for: path)
                    return .socialImageLink(url)
                })
                //.meta(.name("theme-color"), .content("#FD5C48"))
            ),
                .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Main {
                    Div {
                        HTMLSection {
                            Image(url: "/profile.jpeg", description: "profile picture").class("profilepic")
                            index.content.body
                        }
                        HTMLSection {
                            Link(url: "/apps") { H1("My Apps") }
                            ItemList(
                                items: context.allItems(
                                    sortedBy: \.date,
                                    order: .descending
                                ).filter({ $0.sectionID.rawValue == Homepage.SectionID.apps.rawValue })
                                    .filter({ ($0.metadata as? Homepage.ItemMetadata)?.app != nil }),
                                site: context.site
                            )
                        }
                        //                    HTMLSection {
                        //                    Link(url: "/blog") { H1("Blog Posts") }
                        //                    ItemList(
                        //                        items: context.allItems(
                        //                            sortedBy: \.date,
                        //                            order: .descending
                        //                        ).filter({ $0.sectionID.rawValue == Homepage.SectionID.blog.rawValue }),
                        //                        site: context.site
                        //                    )
                        //                    }
                    }
                }
                SiteFooter()
            }
        )
    }

    func makeSectionHTML(for section: Publish.Section<Site>, context: Publish.PublishingContext<Site>) throws -> Plot.HTML {
        HTML(
                .lang(context.site.language),
                .head(
                    .encoding(.utf8),
                    .meta(.name("url"), .content(context.site.url(for: section.path).absoluteString)),
                    .element(named: "title", text: "\(context.site.name) · \(section.title)"),
                    .meta(.name("description"), .content(context.site.description)),
                    .forEach(["/styles.css"], { .stylesheet($0) }),
                    .viewport(.accordingToDevice),
                    .unwrap(context.site.favicon, { .favicon($0) }),
                    .link(
                        .rel(HTMLLinkRelationship(rawValue: "apple-touch-icon")!),
                        .href("/apple-touch-icon.png")
                ),
                    .rssFeedLink(Path.defaultForRSSFeed.absoluteString, title: "Subscribe to \(context.site.name)")
            ),
                .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Text("").addLineBreak() // this is a hack but I don't care to implement an actual solution.
                H1(html: section.title)
                ReturnToHomepageLink
                Main {
                    ItemList(
                        items: context.allItems(
                            sortedBy: \.date,
                            order: .descending
                        ).filter({ $0.sectionID.rawValue == section.id.rawValue }),
                        site: context.site
                    )
                }
                ReturnToHomepageLink
                SiteFooter()
            }
        )
    }

    func makeItemHTML(for item: Publish.Item<Site>, context: Publish.PublishingContext<Site>) throws -> Plot.HTML {
        HTML(
                .lang(context.site.language),
                .head(
                    .encoding(.utf8),
                    .meta(.name("url"), .content(context.site.url(for: item.path).absoluteString)),
                    .element(named: "title", text: "\(context.site.name) · \(item.title)"),
                    .meta(.name("description"), .content(context.site.description)),
                    .forEach(["/styles.css"], { .stylesheet($0) }),
                    .viewport(.accordingToDevice),
                    .unwrap(context.site.favicon, { .favicon($0) }),
                    .link(
                        .rel(HTMLLinkRelationship(rawValue: "apple-touch-icon")!),
                        .href("/apple-touch-icon.png")
                ),
                    .rssFeedLink(Path.defaultForRSSFeed.absoluteString, title: "Subscribe to \(context.site.name)"),
                    .unwrap((item.metadata as? Homepage.ItemMetadata)?.app?.appleID, { appleID in
                            .meta(.name("apple-itunes-app"), .content("app-id=\(appleID)"))
                    }),
                    .unwrap(item.imagePath ?? context.site.imagePath, { path in .socialImageLink(context.site.url(for: path)) })
                //.meta(.name("theme-color"), .content("#FD5C48"))
            ),
                .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Main {
                    if let metadata = item.metadata as? Homepage.ItemMetadata, let _ = metadata.app {
                        try! App(for: item)
                    } else if item.path.string.contains("apps") {
                        try! AppSubSite(for: item)
                    } else {
                        try! BlogPost(for: item)
                    }
                }
                SiteFooter()
            }
        )
    }

    func makePageHTML(for page: Publish.Page, context: Publish.PublishingContext<Site>) throws -> Plot.HTML {
        HTML(
                .lang(context.site.language),
                .head(
                    .encoding(.utf8),
                    .meta(.name("url"), .content(context.site.url(for: page.path).absoluteString)),
                    .element(named: "title", text: "\(context.site.name) · \(page.title)"),
                    .meta(.name("description"), .content(context.site.description)),
                    .forEach(["/styles.css"], { .stylesheet($0) }),
                    .viewport(.accordingToDevice),
                    .unwrap(context.site.favicon, { .favicon($0) }),
                    .link(
                        .rel(HTMLLinkRelationship(rawValue: "apple-touch-icon")!),
                        .href("/apple-touch-icon.png")
                ),
                    .rssFeedLink(Path.defaultForRSSFeed.absoluteString, title: "Subscribe to \(context.site.name)")
            ),
                .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Main {
                    Div {
                        page.content.body
                    }
                }
                SiteFooter()
            }
        )
    }

    func makeTagListHTML(for page: Publish.TagListPage, context: Publish.PublishingContext<Site>) throws -> Plot.HTML? {
        return nil
    }

    func makeTagDetailsHTML(for page: Publish.TagDetailsPage, context: Publish.PublishingContext<Site>) throws -> Plot.HTML? {
        return nil
    }
}

func AppPreview(for item: Publish.Item<some Website>) throws -> Plot.Component {
    guard let itemMetadata = item.metadata as? Homepage.ItemMetadata else { throw NSError(domain: "publish", code: 0) }
    guard let app = itemMetadata.app else { throw NSError(domain: "publish", code: 0) }
    return Article {
        Div {
            Link(url: item.path.absoluteString) {
                Image("/apps/\(item.title)/AppIcon.png").class("appicon")
            }
            Div {
                if let url = app.masLink { Link(url: url) { Image("/badges/mas.svg") } }
                if let url = app.iasLink { Link(url: url) { Image("/badges/ias.svg") } }
                if let url = app.atfLink { Link(url: url) { Image("/badges/atf.svg") } }
//                if !short { Link(url: "privacy", label: { Image("/badges/pp.svg") }) }
            }.class("appstore-badges").class("asb-left").class("asb-left2")
        }.class("app-preview-flavor")
        Div {
            Div {
                if let url = app.masLink { Link(url: url) { Image("/badges/mas.svg") } }
                if let url = app.iasLink { Link(url: url) { Image("/badges/ias.svg") } }
                if let url = app.atfLink { Link(url: url) { Image("/badges/atf.svg") } }
            }.class("appstore-badges").class("asb-right")
            Node<Any>.raw(
                item.content.body.html
                    .components(separatedBy: "</p>").first!
                    .replacingOccurrences(of: "<h1>", with: "<a href=\"\(item.path.absoluteString)\"><h1>")
                    .replacingOccurrences(of: "</h2>", with: "</h2></a>")
//                        .fixingMarkdown()
                + "<a href=\"\(item.path.absoluteString)\" class=\"more-link\">Read more&#8230;</a>"
                    + "</p>")
        }.class("app-preview-body")
    }.class("app-preview")
}

func App(for item: Publish.Item<some Website>) throws -> Plot.Component {
    guard let itemMetadata = item.metadata as? Homepage.ItemMetadata else { throw NSError(domain: "publish", code: 0) }
    guard let app = itemMetadata.app else { throw NSError(domain: "publish", code: 0) }
    return ComponentGroup {
        Aside {
            Image("/apps/\(item.title)/AppIcon.png").class("appicon")
            Div {
                if let url = app.masLink { Link(url: url) { Image("/badges/mas.svg") } }
                if let url = app.iasLink { Link(url: url) { Image("/badges/ias.svg") } }
                if let url = app.atfLink { Link(url: url) { Image("/badges/atf.svg") } }
//                if !short { Link(url: "privacy", label: { Image("/badges/pp.svg") }) }
                    if let url = app.mastodonLink { (Link(url: url) { Image("/badges/mastodon.svg") }).attribute(named: "rel", value: "me") }
                    Link(url: "privacy", label: { Text("Privacy Policy") })
            }.class("appstore-badges").class("asb-left2")
        }
        Article {
            item.content.body
            Div {
                if let url = app.masLink { Link(url: url) { Image("/badges/mas.svg") } }
                if let url = app.iasLink { Link(url: url) { Image("/badges/ias.svg") } }
                if let url = app.atfLink { Link(url: url) { Image("/badges/atf.svg") } }
                if let url = app.mastodonLink { (Link(url: url) { Image("/badges/mastodon.svg") }).attribute(named: "rel", value: "me") }
            }.class("appstore-badges").class("asb-bottom")
            ReturnToHomepageLink
        }
    }
}

func ReturnToAppLink(for path: Path) -> Component {
    BackLink(to: "/" + path.string.split(separator: "/").prefix(2).joined(separator: "/"), titled: String(path.string.split(separator: "/").prefix(2).last ?? "NOAPP"))
}

var ReturnToBlogLink: Component {
    BackLink(to: "/blog", titled: "All posts")
}

var ReturnToHomepageLink: Component {
    BackLink(to: "/", titled: "Return to homepage")
}

func BackLink(to targetURL: String, titled title: String) -> Component {
    Link(url: targetURL) { Text("← \(title)") }.class("home-link")
}

var BlogPostDateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM d, Y"
    return dateFormatter
}

var ISODateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "Y-MM-dd"
    return dateFormatter
}

func AppSubSite(for item: Publish.Item<some Website>, short: Bool = false) throws -> Plot.Component {
    let preProcessedContent = item.content.body.html
        .replacing("<h1>", with: short ? "<a href=\"\(item.path.absoluteString)\"><h2>" : "<h1>", maxReplacements: 1)
        .replacing("</h1>", with: (short ? "</h2></a>" : "</h1>") + "<span class=\"post-date\">\(BlogPostDateFormatter.string(from: item.date))</span>", maxReplacements: 1)
    return Article {
        if !short {
            ReturnToHomepageLink
            ReturnToAppLink(for: item.path)
        }
        Node<Any>.raw(
            short ? preProcessedContent.components(separatedBy: "</p>").first!
                + "<a href=\"\(item.path.absoluteString)\" class=\"more-link\">Read more&#8230;</a>"
                + "</p>": preProcessedContent)
        if !short {
            ReturnToAppLink(for: item.path)
            ReturnToHomepageLink
        }
    }
}

func BlogPost(for item: Publish.Item<some Website>, short: Bool = false) throws -> Plot.Component {
    let preProcessedContent = item.content.body.html
        .replacing("<h1>", with: short ? "<a href=\"\(item.path.absoluteString)\"><h2>" : "<h1>", maxReplacements: 1)
        .replacing("</h1>", with: (short ? "</h2></a>" : "</h1>") + "<span class=\"post-date\">\(BlogPostDateFormatter.string(from: item.date))</span>", maxReplacements: 1)
    return Article {
        if !short {
            ReturnToHomepageLink
            ReturnToBlogLink
        }
        Node<Any>.raw(
            short ? preProcessedContent.components(separatedBy: "</p>").first!
                + "<a href=\"\(item.path.absoluteString)\" class=\"more-link\">Read more&#8230;</a>"
                + "</p>": preProcessedContent)
        if !short {
            ReturnToBlogLink
            ReturnToHomepageLink
        }
    }
}

private struct ItemList<Site: Website>: Component {
    var items: [Item<Site>]
    var site: Site

    var body: Component {
        var itemsToUse = items
        if items.contains(where: { ($0.metadata as? Homepage.ItemMetadata)?.app != nil }) {
            itemsToUse = items.filter({ ($0.metadata as? Homepage.ItemMetadata)?.app != nil })
        }
        return List(itemsToUse) { item in
            if let itemMetadata = item.metadata as? Homepage.ItemMetadata, let _ = itemMetadata.app {
                return try! AppPreview(for: item)
            } else if item.path.string.contains("apps") {
                return try! AppSubSite(for: item, short: true)
            } else {
                return try! BlogPost(for: item, short: true)
            }
        }.class("article-list")
    }
}


private struct SiteFooter: Component {
    var body: Component {
        Footer {
            Span {
                //                Text("Generated using ")
                //                Link("Publish", url: "https://github.com/johnsundell/publish")
                //                Text(" · ")
                Link("Colophon", url: "/colophon")
                Text(" · ")
                Link(url: "/feed.rss") { Node<Any>.raw(fixText(for: "^rss^ feed")) }
            }
            Span {
                Link("Impressum", url: "/impressum").class("badlink")
                Text(" · ")
                Link("Privacy", url: "/privacy").class("badlink")
            }
        }
    }
}

private struct SiteHeader<Site: Website>: Component {
    var context: PublishingContext<Site>
    var selectedSelectionID: Site.SectionID?

    var body: Component {
        Header {
            Link(context.site.name, url: "/")
                .class("site-name")

//            if Site.SectionID.allCases.count > 1 {
//                navigation
//            }
            Span {
                Link(url: "mailto:Hans%20Schülein<mail@hans.coffee>") { Image(url: "/icons/mail.png", description: "Mail").class("icon") }
//                Link(url: "https://twitter.com/SherlockHans") { Image(url: "/icons/twitter.svg", description: "Twitter").class("icon") }
                Link(url: "https://mastodon.social/@SherlockHans") { Image(url: "/icons/mastodon.png", description: "Mastodon").class("icon") }.attribute(named: "rel", value: "me")
                Link(url: "https://github.com/Kamik423") { Image(url: "/icons/github.png", description: "GitHub").class("icon") }
            }
        }
    }

    private var navigation: Component {
        Navigation {
            List(Site.SectionID.allCases) { sectionID in
                let section = context.sections[sectionID]
                return Link(section.title, url: section.path.absoluteString)
                    .class(sectionID == selectedSelectionID ? "selected" : "")
            }
        }
    }
}
