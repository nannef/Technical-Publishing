// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let unescape-eval(str) = {
  return eval(str.replace("\\", ""))
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#show table: it => {
  set text(size: 7pt)
  set par (
    justify: false
  )
  it
}
#show heading: it => [
  #it
  #v(0.6em)
]
#show figure.caption: set align(left)
#show footnote.entry: it => {
  set par(first-line-indent: 0em)
  [#h(-1em)#it]  // Pulls the number back
}

#show: doc => article(
  title: [Measurement and verification of environmental and social outcomes for a proposed Australian Impact Exchange],
  authors: (
    ( name: [Arlette Schram, Marianne Feoli, Ben Milligan],
      affiliation: [UNSW Centre for Sustainable Development Reform],
      email: [b.milligan\@unsw.edu.au] ),
    ),
  date: [2024-11-10],
  abstract: [Impact Exchanges require distinct measurement frameworks across asset classes (corporate securities, impact investments, commodities) due to fundamental differences in how environmental and social outcomes are quantified, verified, and reported within each market segment. We propose use of a "meta-standards" approach for incorporating measurement of environmental and social outcomes—establishing overarching principles for outcome measurement while allowing methodological flexibility - supported by a technical committee to ensure market integrity and framework interoperability. Short-term market demands for simple metrics must be balanced against systemic risks, as evidenced by carbon markets where inadequate standardization and verification led to market fragmentation and credibility issues.],
  abstract-title: "Summary.",
  margin: (bottom: 2cm,left: 2cm,right: 2cm,top: 2cm,),
  paper: "a4",
  fontsize: 10pt,
  sectionnumbering: "1.1.1",
  toc: true,
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Summary of key findings
<summary-of-key-findings>
- Measurement and verification of environmental and social outcomes to inform financial investment is a rapidly evolving field. A wide variety of measurement and verification methods are currently used to assess the environmental and social performance of diverse financial instruments for diverse asset classes. These methods are commonly applied as a subset of overarching frameworks and standards implementation—for positive and negative environmental, social and governance (ESG) screening, impact investment, corporate disclosure of impacts and dependencies, sustainability certification or benchmarking, and other topic areas. These frameworks and standards are characterised by highly varied degrees of: formal standardisation, public or private sector involvement, intellectual property licensing models, and transparency.

- Establishing public exchanges based on verified environmental and social outcomes ("Impact Exchanges") involves careful design choices—about the specific measurement and verification methods, frameworks and standards that determine market disclosures. These design choices depend fundamentally on the scope of assets or instruments that can be traded—for example Impact Exchanges focused on:

  - corporate securities might be best underpinned by holistic disclosure frameworks such as those maintained by the Capitals Coalition (e.g.~the Natural Capital Protocol), or Taskforces for Nature-Related, and Climate-Related Financial Disclosures (TNFD and TCFD respectively).

  - enabling impact investment might be best underpinned by the existing dedicated frameworks such as Global Impact Investing Network’s (GIIN) IRIS+, the Social Return on Investment (SROI), the Social Performance Task Force (SPTF), B Impact Assessment (BIA) by B Lab, and the Impact Management Project (IMP).

  - commodities or real property may be well matched with primary low-level measurement frameworks such as those developed for specific sectoral raw material supply chains (e.g.~apparel, minerals and metals, etc), or environmental characteristics (e.g.~pollution levels, in-situ biodiversity).

- Predicating an Impact Exchange on specific primary outcome methods is fraught with risk—the Australian and global political economy for environmental and social measurement, verification, and reporting in characterised by rapid innovation and is far from a state of maturity. Different frameworks and standards have highly heterogenous subject matter scopes, methodological design and underlying commercial or values-based imperatives. This complicates any assessment of trade-offs between different exchange design choices, and creates risks of adverse consequences and path dependencies if premature choices are made to adopt certain methods, frameworks or standards.

- In the near term, we recommend a "meta-standards" approach to the design of the proposed Australian Impact Exchange (AIX) that focuses on preserving market integrity through transparent, principles-based and market-driven evolution of methods for measurement and verification of environmental and social outcomes. Some candidate principles, which would benefit from further consultation and research, are summarised below:

  - Principle 1: Traded assets should disclose both their primary environmental and social outcomes (quantified or qualified as appropriate) and the methodological basis for assessing those outcomes.

  - Principle 2: The disclosed methodological basis for disclosure should be compatible with certain quality standards intended to support alignment with general fiduciary principles and Australian consumer regulation. They should:

    - Transparently document their definitional foundations, input data and assessment methods. Low-level definitions should be aligned with the System of Environmental-Economic Accounting (SEEA) as appropriate, in particular to avoid confusion between measurement of environmental stocks (e.g.~the extent and/or condition of specific ecosystem types aligned to the IUCN Global Ecosystem Typology) and flows of goods and services from the environment to the economy (e.g.~carbon sequestration, regulation of waste, flows of raw materials)–see Figure 1 below.

    - Clearly document their functional, geographical and value chain scope coverage (e.g.~1+2 vs 3) and use pre-defined categories aligned to the SEEA and other relevant global statistical standards.

- We also suggest that a standing technical committee should be incorporated into the governance planning for the AIX with a clear remit to iteratively refine and develop meta-standards concerning social and environmental outcome disclosure, and facilitate pre-competitive dialogue between different frameworks, standards and approaches.

- A pragmatic alternative to the "meta-standards" approach suggested above would be to establish an Impact Exchange based on clear social and environmental outcome metrics for which there is short-term market demand. One advantage of this approach is the ability to generate liquidity and positive margins that could be reinvested into improving and scaling the Impact Exchange. A key risk is that metrics may evolve in response to ad hoc demand drivers without sufficient attention to generating the coherence, robustness and transparency needed to bring investment in environmental and social outcomes to scale. The fundamental structural deficiencies of both voluntary and statutory carbon markets identified in recent years offers a pertinent cautionary tale.#footnote[See for example: Nature-based credit markets at a crossroads, Nature Sustainability: #link("https://doi.org/10.1038/s41893-024-01403-w");]

#figure([
#box(image("media/Picture 1.png"))
], caption: figure.caption(
position: bottom, 
[
Conceptual basis for organising environmental, social and economic metrics aligned to international statistical standards. Source: #link("https://seea.un.org/content/about-seea")
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= Introduction
<introduction>
+ The Digital Finance Cooperative Research Centre (DFCRC) is exploring research and commercialisation opportunities in sustainable finance, with a specific focus on how can digital finance toolkits be used to unlock the resources needed to transition Australia towards a more resilient, decarbonised, regenerative and just economy. As part of this agenda, the DFCRC is pursuing a project—referred to as the Australian Impact Exchange project—to develop a public digital marketplace for trading debt and equity securities in entities/ assets/funds that deliver financial returns and verified environmental and social outcomes.

+ This Research Brief documents key findings of short-term research undertaken by the UNSW Centre for Sustainable Development Reform (CSDR) intended to inform the design of AIX pilot projects. The Brief addresses the aspects of measuring and verifying the performance of different impact dimensions—exploring existing and emerging standards, their purpose, scope, and market acceptance, and key implications relevant to the AIX project. Consistent with the expertise focus of CSDR staff, findings place a greater emphasis on nature-related measurement and verification. The findings are preliminary and subject to revision based on ongoing consultation with relevant DFCRC stakeholders.

= Preliminary Comments Concerning AIX
<preliminary-comments-concerning-aix>
#block[
#set enum(numbering: "1.", start: 3)
+ The AIX project seeks to create a marketplace for trading securities that deliver verified environmental and social impact alongside financial returns. Accurate and credible impact measurement and verification are essential for the success of the AIX project, as they ensure that investments genuinely contribute to sustainability goals. The research will help establish standards and frameworks, filling gaps and setting benchmarks that enhance transparency, credibility, and market acceptance in sustainable finance.

+ Socially responsible investing (SRI) encompasses a variety of strategies that focus on sustainability objectives alongside financial returns. These strategies range from impact investing to ESG incorporation and green/blue finance. Each strategy employs different objectives and can be applied to asset classes such as credits, publicly and privately traded securities, project-level initiatives, alternative investments, or other assets.

+ Expanding the scope of the AIX from focusing solely on impact investment to include other SRI strategies can enhance its appeal and effectiveness. For example, investing in vehicles that employ ESG incorporation can encourage best-practice industry leaders by integrating ESG factors into financial analysis and investment decisions, aligning with standards like the Taskforce on Nature-related Financial Disclosures (TNFD). At the same time, ESG performance strategies can actively engage companies to improve their practices and continuously track ESG momentum. Impact investing can unlock novel nature-based solutions or encourage capital flow towards the circular economy. Green finance can fund projects with specific environmental benefits through instruments like green and climate bonds, while social finance strategies can address pressing social issues through social and impact bonds. Governance and ethical strategies, such as active ownership and corporate governance investing, can drive corporate change and align investments with personal values. Measuring and verifying impact refers to the positive environmental or social impacts of impact investment.

+ Extending beyond impact investments can broaden the scope of the AIX and create a tailored approach to assessing and driving sustainable development outcomes overall. A comprehensive overview of suitable investment strategies to implement in AIX can be found in the tables in the Appendix.

+ Impact investment focuses on key characteristics such as intentionality#footnote[Intentionality is a fundamental aspect of impact investing; investors must explicitly state their intention to generate social or environmental benefits (GIIN, 2022).];, measurability#footnote[Impact investments must have measurable outcomes, which should be quantifiable on a qualitative or quantitative basis, and performance must be reported transparently (Bundesinitiative Impact Investing; GIIN, 2022).];, additionality#footnote[Additionality refers to the unique impact an investment would only have achieved with the specific funding. Active investor engagement and sharing best practices are vital for attaining additionality and fostering growth in impact investing (Bundesinitiative Impact Investing; GIIN, 2022).] and evidence-based#footnote[Using evidence to substantiate the intended impact is essential in impact investing, which involves using data and research to guide investment decisions and prove that investments lead to meaningful social or environmental changes (GIIN, 2022).];, ensuring that investments create positive outcomes that would not occur otherwise. Impact Investments must align with fiduciary duty and social investing, which requires asset managers to act in the best interest of beneficiaries and ensure investments align with specified social or environmental objectives (Finance UNEP Initiative, 2020).
]

#block[
#set enum(numbering: "1.", start: 8)
+ In contrast, ESG reporting focuses on the broader disclosure of an organisation’s environmental, social, and governance practices. Standards such as the Global Reporting Initiative (GRI), Sustainability Accounting Standards Board (SASB), Task Force on Climate-related Financial Disclosures (TCFD), and the Greenhouse Gas Protocol (GHG Protocol) help organisations provide transparent information on their ESG performance, manage related risks, and ensure regulatory compliance. Integrating various strategies within AIX could be beneficial to ensure robust impact measurement and verification, enhancing credibility and effectiveness in driving sustainable development:
]

#figure([
#box(image("media/Picture 2.png"))
], caption: figure.caption(
position: bottom, 
[
Methodology for market studies on sustainability-related investments. Source: #link("https://www.eurosif.org/wp-content/uploads/2024/02/2024.02.15-Final-Report-Eurosif-Classification_2024.pdf")
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#set enum(numbering: "1.", start: 9)
+ The AIX will need to adhere to the characteristics of each asset and strategy to ensure investments deliver verified social and environmental outcomes alongside financial returns. The assessment should be conducted before investment, with ongoing reporting to measure impact during the investment and the use of appropriate reporting standards for communicating effect in the form of reporting.

+ The landscape of reporting standards, guidance, and measurement frameworks is broad and often subject to national regulations, legislation, objectives, and approaches. For AIX to ensure that investments are financially viable and contribute meaningfully to social and environmental goals, it is recommended that this landscape be analysed and a comprehensive measurement and verification approach be created. Such an approach would require developing a "meta" governance structure based on inclusive and comprehensive standards.
]

= Current landscape of measurement and verification standards
<current-landscape-of-measurement-and-verification-standards>
#block[
#set enum(numbering: "1.", start: 11)
+ A thorough analysis of the measurement and verification standards landscape ensures that investments within the AIX contribute to social, socio-economic and environmental goals. The meta-governance structure should integrate the critical aspects of commonly used standards tailored to different socially responsible investing strategies. For company reporting, frameworks such as the Global Reporting Initiative (GRI), the Taskforce on Nature-related Financial Disclosures (TNFD), the Task Force on Climate-related Financial Disclosures (TCFD), and the Sustainability Accounting Standards Board (SASB) provide essential guidelines for companies to report their ESG performance.

+ These guidelines help generate verified scores that can be used on the AIX to assess ESG score measurement and verification, offering transparency and credibility to investors and helping them understand the efficiency and implementation of an ESG-based investment strategy. For investor reporting, standards like the UN Principles for Responsible Investment (UNPRI), the Global Impact Investing Network (GIIN), and the Impact Management Project (IMP) guide investors in aligning their strategies with responsible investment principles and measuring impact. These standards can be leveraged within the AIX marketplace to provide investors with precise, standardised data, facilitating informed decision-making and ensuring that investments, such as impact investments, meet desired social and environmental criteria.

+ Regarding GHG emissions, accounting approaches range from VERRA and Accounting for Nature to the ISO standards and the EU Emissions Trading System (EU ETS). Comprehensive ecosystem assessments can rely on the System of Environmental-Economic Accounting (SEEA), which can build a critical basis for integrating more holistic and comprehensive impact assessments. While IRIS+ is commonly used to quantify or report qualitatively on the impact of impact investments, integrating SEEA can enhance the ability to assess broader ecological impacts systematically and from a more holistic perspective. Incorporating varied frameworks can support the robust and transparent outcome measurement and verification of a digital finance exchange, foster trust, and attract diverse investors.
]

== Categorisation of measurement and verification standards
<categorisation-of-measurement-and-verification-standards>
#block[
#set enum(numbering: "1.", start: 14)
+ The current measurement and verification standards landscape for institutional investment can be differentiated based on the applied strategy (for example, ESG) or impact dimensions such as climate, ecological health, and social impact. This classification can help identify the relevant standards for each dimension, guiding principles, and frameworks. The impact dimensions cover the primary areas where impacts occur and are reported on, aligning them with the AIX project’s objectives. The following illustration by the IRIS shows the interconnectedness of IRIS+ impact categories and themes as of May 2021 and can help guide meta governance structures for desired outcomes:
]

#figure([
#box(image("media/Picture 3.jpg"))
], caption: figure.caption(
position: bottom, 
[
Interconnectedness of IRIS+ Impact Categories and Themes as of May 2021
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#set enum(numbering: "1.", start: 15)
+ The following paragraphs discuss different groups of impact dimensions, relevant standards, and guiding frameworks for impact and ESG assessment, where applicable across the following general tiers:
]

#figure([
#box(image("media/Picture 4.jpg"))
], caption: figure.caption(
position: bottom, 
[
Illustrative tiers of analytical approaches to impact and ESG assessment
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#set enum(numbering: "1.", start: 16)
+ Dividing the structure of the impact assessment within the AIX, pursuant to categories such as those shown in Tier 3 makes is easier to identify and apply the applicable standards for specific types of measurement and verification.
]

== A holistic conceptual framework grounded in national accounting standards
<a-holistic-conceptual-framework-grounded-in-national-accounting-standards>
#block[
#set enum(numbering: "1.", start: 17)
+ The System of Environmental-Economic Accounting (SEEA) is a framework that integrates environmental and economic data to provide a detailed understanding of the interactions between the environment and the economy. SEEA is designed to measure the stocks and flows of natural resources, including water, forests, minerals, and land, as well as the services these resources provide. It offers a standardised approach to capturing the economic value of natural capital and the costs associated with environmental degradation and resource depletion. By linking ecological data with economic accounts, SEEA enables policymakers, researchers, and environmental managers to assess the sustainability of economic activities and make informed decisions about resource management and environmental conservation.

+ SEEA consists of several components, including physical flow, environmental asset, and monetary flow accounts. Physical flow accounts track the movement of natural inputs, products, and residuals between the environment and the economy. Environmental asset accounts monitor the stocks and changes in natural resource stocks over time, providing insights into the availability and use of resources. Monetary flow accounts record the economic transactions related to environmental protection and resource management, such as expenditures on pollution control and investments in renewable energy. SEEA provides a holistic view of how natural capital contributes to economic well-being and how economic activities impact the environment. This integrated approach makes SEEA a valuable tool for assessing the sustainability of development practices, evaluating the effectiveness of environmental policies, and guiding strategic planning for sustainable development.

+ Adopting SEEA as the foundational framework for the AIX meta-governance ensures a robust, integrated approach to assessing and driving sustainable development outcomes. SEEA provides the date to establish a baseline for evaluating the effectiveness of impact reporting initiatives such as IRIS+ and the Impact Management Project (IMP). These initiatives focus on specific impact metrics but can lack a comprehensive perspective on broader environmental and socio-economic outcomes. Using SEEA as a core conceptual organising framework offers the following advantages:

  - Benchmark Impact Reporting: SEEA’s comprehensive data framework on natural resource stocks, flows, and economic transactions provide a benchmark against which the impacts reported by initiatives like IRIS+ can be compared.

  - Verify Outcomes: SEEA’s standardised framework can be used to verify reported impacts, ensuring that they reflect real improvements in ecological health and resource management. This can help identify discrepancies between reported impacts and actual outcomes within ecosystems.

  - Understand Holistic Impacts: SEEA’s integration of environmental and economic data helps understand how specific impacts contribute to broader sustainability goals. For instance, while an initiative may report positive social impact, SEEA can provide insights into whether these social improvements also lead to sustainable environmental outcomes and support quantifying those improvements.

  - Identify Gaps and Opportunities: By comparing impact reports with SEEA data, AIX can identify areas where impact initiatives may fall short or overlook critical aspects of sustainability. This can guide the deployment of capital towards effective impact investment.

  - Support Strategic Planning: SEEA’s holistic approach aids in strategic planning by providing a detailed understanding of the interactions between economic activities and natural resources. This enables AIX to design investment strategies that are both financially viable and environmentally sustainable.
]

== Socially responsible investment strategies
<socially-responsible-investment-strategies>
#block[
#set enum(numbering: "1.", start: 20)
+ Within the broad range of Environmental, Social and Governance (ESG) Reporting Standards, Climate-related disclosure and reporting standards, such as the Task Force on Climate-related Financial Disclosures (TCFD) and the Carbon Disclosure Project (CDP), guide companies in presenting environmental and social-related information transparently and comprehensively in their financial reports and other disclosures. These standards are crucial: quantification standards ensure accurate emissions data, while disclosure standards promote transparency and informed decision-making, driving regulatory compliance and market trust. The table below summarises existing and commonly used climate-related disclosure and reporting standards:
]

#block[
#table(
  columns: (2.49%, 18.15%, 16.37%, 17.79%, 27.76%, 17.44%),
  align: (left,left,left,left,left,left,),
  table.header([Region], [Standard], [Scope], [Coverage], [Purpose], [Market.Acceptance],),
  table.hline(),
  [Global], [Taskforce on Climate-related Financial Disclosures], [Climate-related financial disclosures], [Climate risk and opportunities], [Provide recommendations for diclosing climate-related risks and opportunities], [Wide adopted espectially in finance],
  [Global], [Carbon Disclosure Project], [Climate and environmental reporting], [Climate change, water, security, deforestation], [Enable compnaies to measure and manage their environmental impacts], [Widely used globally],
  [Global], [Integrated Reporting], [Financial, social and environmental reporting], [Financial performance, ecological, social metrics], [Promote transparency and holistic reporting], [Increasingly adopted by companies],
  [Global], [Science-based Targets Initiative], [Set science-based climate targets], [Corporate GHG emissions], [Help companies set GHG reduction targets in line with climate science], [Widely recognised especially in corporate sector],
  [USA], [Sustainability Accounting Standards Board], [Industry-specific standards], [Environmental, social, governance], [Provide industry-specific standards], [Growing adoption particularly in the US],
  [Global], [Climate Disclosure Standards Board], [Climate-related financial disclosures], [Environmental information], [Integrate climate-related information into mainstream financial reporting], [Increasingly recognised globally],
  [Global], [Global Reporting Initiative], [Sustainability reporting standards], [environmental, social, governance], [Provide comprehensive sustainability reporting guidelines], [Widely used globally],
)
]
#block[
#set enum(numbering: "1.", start: 21)
+ The figure below illustrates the role of guiding principles and frameworks for ESG investment assessment from an investor perspective. Their associated indices and assessment support tools are crucial for investors looking to integrate ESG factors into their investment decisions. They help investors assess their portfolio’s sustainability and ethical impacts, driving informed investment strategies.
]

#figure([
#box(image("media/Picture 5.jpg"))
], caption: figure.caption(
position: bottom, 
[
Role of guiding principles and frameworks for ESG investment assessment
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#set enum(numbering: "1.", start: 22)
+ Impact investment refers to investments made to generate positive, measurable social and environmental benefits alongside a financial return (Godeke & Briaud, 2021; Bundesinitiative Impact Investing; GIIN, 2022). The figure below illustrates the role of key guiding principles and frameworks for assessment of impact investment performance, alongside key measurement and verification approaches.
]

#figure([
#box(image("media/Picture 6.jpg"))
], caption: figure.caption(
position: bottom, 
[
Role of guiding principles and frameworks for ESG investment assessment
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#set enum(numbering: "1.", start: 23)
+ IRIS+ provides a comprehensive global catalogue of metrics impact investors use to measure social, environmental, and financial performance across sectors such as education, healthcare, and economic development. SROI translates social outcomes into monetary values, offering a method to measure social value created by investments in various sectors, including community development and healthcare. SPTF focuses on assessing social performance in the microfinance sector, while BIA evaluates companies’ social and environmental performance, emphasising governance, workers, community, environment, and customers. IMP provides a consensus on measuring, managing, and reporting impacts on people and the planet, covering multiple sectors and impact themes.

+ Each framework has specific requirements for measurement and verification. IRIS+ and IMP emphasise standardised metrics and consistent data collection, with third-party audits often used for verification. SROI requires detailed data on inputs, outputs, and financial proxies, with stakeholder engagement and third-party validation. SPTF uses outreach and social responsibility indicators, with self-reporting and external audits. BIA involves a structured questionnaire and comprehensive assessment, verified through third-party audits for B Corp certification. The most widely accepted standards include IRIS+, IMP, and BIA, which are highly regarded globally among impact investors and financial institutions. SROI and SPTF are also gaining acceptance, particularly in the non-profit and microfinance sectors.

+ Despite their wide acceptance, these frameworks often overlap in their methodologies and objectives. For example, IRIS+ and IMP share common elements in defining and standardising impact metrics. However, gaps remain in sector-specific metrics for niche areas and challenges in assigning monetary values to all social outcomes, as seen with SROI. Understanding these overlaps and gaps is crucial for developing a comprehensive and credible impact assessment strategy, ensuring investments align with broader social and environmental goals.
]

== Measurement and verification: climate change and GHG emissions
<measurement-and-verification-climate-change-and-ghg-emissions>
#block[
#set enum(numbering: "1.", start: 26)
+ The Greenhouse Gas Protocol (GHG Protocol) and ISO 14064 are globally accepted standards and provide universal frameworks for measuring and managing emissions. The landscape of GHG accounting standards is broad, and some standards are more specific to certain regions due to factors like regulatory requirements, which entail adherence to local laws and policies. Market acceptance varies by region and is influenced by local stakeholder expectations and economic contexts. This regional differentiation ensures that standards align with unique environmental priorities, financial structures, and cultural factors, facilitating compliance and enhancing strategic implementation for organisations.

+ The GHG Protocol and ISO 14064 are mature and widely adopted standards that provide comprehensive frameworks. Their global acceptance and methodologies make them essential tools for organisations committed to transparency, regulatory compliance, and effective climate action. The GHG protocol provides comprehensive standards and guidelines for organisations to quantify and report their GHG emissions, covering various sectors and activities. It provides methodologies for calculating emissions from direct (Scope 1), indirect energy (Scope 2), and other indirect sources (Scope 3).

  - ISO 14064 is an international standard developed by the International Organization for Standardization (ISO) that provides guidelines and requirements for greenhouse gas emissions and removals. ISO 14064 is divided into three parts:
  - ISO 14064-1: Specifies principles and requirements for quantifying and reporting GHG emissions and removals at the organisation level.
  - ISO 14064-2: Guides at the project level for quantifying, monitoring, and reporting GHG emission reductions or removal enhancements.
  - ISO 14064-3 Offers guidelines for validating and verifying GHG assertions, ensuring the accuracy and reliability of GHG reports.

+ Other standards that focus on climate change and GHG emissions are outlined below:
]

#block[
#table(
  columns: (4.73%, 18.18%, 22.91%, 9.82%, 26.91%, 17.45%),
  align: (left,left,left,left,left,left,),
  table.header([Region], [Standard], [Scope], [Coverage], [Purpose], [Market.Acceptance],),
  table.hline(),
  [Global], [Greenhouse Gas Protocol (GHG Protocol)], [Corporate, Project, Value Chain (Scope 1, 2, 3)], [Global], [Provide standardized approach for GHG accounting transparency consistency], [Widely adopted by businesses, governments, NGOs],
  [Global], [ISO 14064], [Organization (Part 1), Project (Part 2), Verification (Part 3)], [Global], [Guidelines for quantifying, reporting, and verifying GHG emissions], [Widely recognized and implemented globally],
  [Europe], [EU Emissions Trading System (EU ETS)], [Cap-and-trade system for power, industry, aviation], [Europe], [Regulate and reduce GHG emissions through a cap-and-trade system], [Major compliance tool in Europe],
  [Africa], [African Regional Standard (ARS 902)], [GHG emissions inventory], [Africa], [Standardized approach for GHG emissions inventory], [Increasing adoption across African countries],
  [Africa], [South Africa’s NGER Regulations], [Mandatory GHG reporting], [South Africa], [Regulatory compliance and GHG management], [Key regulation in South Africa],
  [Americas], [California Cap-and-Trade Program], [Cap-and-trade system for emissions], [United States (California)], [Regulate and reduce GHG emissions through a cap-and-trade system], [Major compliance tool in California],
  [Americas], [Climate Registry General Reporting Protocol (GRP)], [Voluntary GHG reporting], [Americas], [Standardize GHG emissions reporting for voluntary programs], [Widely used in North America],
  [Asia Pacific], [Japan’s GHG Accounting and Reporting System], [Mandatory GHG reporting], [Japan], [Regulatory compliance and GHG management], [Major regulation in Japan],
)
]
== Measurement and verification of ecological health
<measurement-and-verification-of-ecological-health>
#block[
#set enum(numbering: "1.", start: 29)
+ Standards for measuring ecological health are essential for protecting and restoring biodiversity and ecosystem services. The frameworks focus on assessing and reporting the condition of natural assets such as soils, vegetation, and fauna. The following paragraphs introduces various ecological health standards and compares them, analysing their purpose, scope, market acceptance, strengths, and weaknesses to highlight their roles in impact measurement.

+ Accounting for Nature is a framework designed to measure and report the condition of environmental assets, offering a standardised approach to assessing ecosystem health. It encompasses a wide range of natural resources, providing data to support informed decision-making in environmental management. Its science-based methodology aims to enhance the understanding and conservation of ecosystems, aligning with global environmental policies.

+ The framework offers extensive geographic coverage, which applies to diverse ecosystems globally, from tropical rainforests to arid landscapes. Its sectoral coverage spans agriculture, forestry, conservation, and urban planning, providing a tool for various environmental management practices. The framework’s impact coverage includes a wide range of ecological assets, such as soils, vegetation, and fauna, ensuring a comprehensive assessment of ecosystem health.

+ The framework employs a set of measurement and verification requirements to ensure accurate and reliable ecological assessments. Environmental Condition Accounts (ECA) and the Environmental Condition Index (Econd®), which ranges from 0 to 100, quantify the state of environmental assets. Indicators must be scientifically validated, and detailed data collection instructions ensure consistency. Reference condition benchmarks represent the asset’s natural or best possible state. Verification involves independent audits by accredited experts to provide methods and data that meet stringent criteria. The framework specifies accuracy levels (95%, 90%, or 80%) to indicate precision, with higher levels requiring more detailed methods. Transparency is maintained through complete documentation of data sources, methodologies, and calculations. Continuous improvement processes ensure the framework incorporates new scientific knowledge and enhances robustness over time.

+ The Natural Capital Protocol#footnote[See: #link("https://capitalscoalition.org/wp-content/uploads/2021/01/NCC_Protocol.pdf");] is a framework for assessing and valuing natural capital impacts and dependencies. It is divided into four stages: Frame, Scope, Measure and Value, and Apply. The Frame stage helps stakeholders understand the importance of evaluating natural capital and introduces them to key concepts. This stage involves preparing for the assessment by understanding the context and objectives and identifying the relevant stakeholders. The Scope stage defines the assessment’s objectives and boundaries and identifies the relevant natural capital impacts and dependencies. This stage sets the parameters for what will be assessed, including the geographical and temporal scope and the specific impacts and dependencies.

+ The Measure and Value stage quantifies and values the identified impacts and dependencies using qualitative, quantitative, and monetary methods. This involves collecting data, applying appropriate valuation techniques, and calculating the overall impact on natural capital. Both biophysical measurement and economic valuation are used to provide a comprehensive assessment. The Apply stage interprets the results, validates their accuracy, and integrates them into decision-making processes. This involves analysing the results, assessing the financial and environmental implications, and communicating the findings to stakeholders.
]

#block[
#set enum(numbering: "1.", start: 35)
+ As outlined in the table below, other frameworks for nature-related measurement and verification have proliferated in recent years, with heterogenous conceptual foundations and scope.
]

#block[
#table(
  columns: (10.4%, 17.92%, 19.08%, 15.32%, 18.79%, 18.5%),
  align: (left,left,left,left,left,left,),
  table.header([Framework], [Purpose], [Scope], [Market.acceptance], [Strengths], [Weaknesses],),
  table.hline(),
  [UN CBD Indicators], [Measures and monitors biodiversity], [Species populations, habitat extent, ecosystem health], [High; used globally for biodiversity targets], [Provides broad biodiversity indicators], [May lack specificity for detailed ecosystem health assessments],
  [IUCN Red List of Ecosystems], [Assesses conservation status of ecosystems], [Risk of ecosystem collapse], [High; recognized globally], [Standardized risk assessment for ecosystems], [Primarily focused on risk, not comprehensive health metrics],
  [Living Planet Index (LPI)], [Tracks changes in global vertebrate species populations], [Population trends of vertebrate species], [High; widely used by conservation organizations], [Provides trends in biodiversity], [Limited to vertebrate species, not all biodiversity],
  [Natural Capital Protocol], [Identifies, measures, and values natural capital impacts], [Ecosystems, biodiversity, ecosystem services], [Widely accepted in corporate sector], [Comprehensive business-oriented impact assessment], [May lack detailed ecological metrics],
  [Ecosystem Services Framework (ESF)], [Assesses and values ecosystem services], [Provisioning, regulating, cultural, supporting services], [Gaining acceptance in policy-making], [Integrates ecological and socio-economic aspects], [Implementation can be complex and subjective],
  [Biodiversity Intactness Index (BII)], [Measures the intactness of biodiversity in a region], [Biodiversity at species level], [Growing in conservation research], [Effective for monitoring biodiversity changes], [Focused primarily on biodiversiy, not broader ecological health],
  [Accounting for Nature], [Measures and reports on the condition of environmental assets], [Ecological health of natural resources (soils, vegetation, fauna)], [Emerging; primarily in Australia, expanding globally], [Standardised ecological health metrics; comprehensive assessment], [Limited broader application until further refinement globally],
)
]
#block[
#set enum(numbering: "1.", start: 36)
+ Several factors are considered when classifying standards according to their widespread acceptance. Accounting for Nature, for example, is an emerging framework primarily developed with a focus on Australia, though it is expanding globally. Its adoption and integration into business and policy processes are still gaining traction. Many organisations and countries are in the early stages of implementing this framework, testing its methodologies, and assessing its practicality and effectiveness. The same can be said about its relevance in impact assessment.

+ On the other hand, the Natural Capital Protocol is widely accepted, having been developed through collaboration with multiple global organisations. It has been broadly adopted by businesses and industries worldwide, encouraging integration with existing business reporting frameworks such as financial and sustainability reporting. This widespread recognition and endorsement by international organisations has led to its higher degree of acceptance and implementation.

+ Accounting for Nature emphasises measuring the condition of environmental assets with a standardised approach to ecological health metrics. While this focus is valuable, it can limit broader application until further refinement and validation across diverse contexts. In contrast, the Natural Capital Protocol offers comprehensive impact measurement, assessing business impacts on natural capital across all industries and geographies. This approach to identifying, measuring, and valuing natural capital impacts makes it more adaptable and relevant for many businesses.
]

== Measurement and verification: social impacts
<measurement-and-verification-social-impacts>
#block[
#set enum(numbering: "1.", start: 39)
+ Leading social impact measures in institutional investment include several prominent frameworks and standards that aim to provide consistency, transparency, and comparability in measuring social outcomes. The frameworks address various constraints in impact investing, such as diverse definitions of impact, the need for internationally comparable data, and underdeveloped impact measurement practices. Among the most recognised frameworks are the Global Impact Investing Network’s (GIIN) IRIS+, the Social Return on Investment (SROI), the Social Performance Task Force (SPTF), B Impact Assessment (BIA) by B Lab, and the Impact Management Project (IMP).

+ The landscape of existing and emerging measurement and verification standards and frameworks for social impact is diverse, commonly used and emerging frameworks can be summarised in the following table:
]

#block[
#table(
  columns: (6.43%, 33.91%, 21.18%, 18.1%, 20.38%),
  align: (left,left,left,left,left,),
  table.header([Framework], [Purpose.and.Coverage], [Average], [Measurement.and.Verification.Requirements], [Overlap.and.Gaps],),
  table.hline(),
  [IRIS+ by GIIN], [Provide a comprehensive catalog of social, environmental, and financial performance metrics. Global; diverse sectors such as education, healthcare, and economic development], [Standardised metrics, consistent data collection, self-assessment, third-party audits.], [Highly accepted globally among impact investors and financial institutions.], [Overlaps with other frameworks like IMP. Gaps in sector-specific metrics for niche areas.],
  [Social Performance Task Force (SPTF)], [Provides standards and guidelines for assessing social performance in microfinance and inclusive finance sectors. Global; specific to microfinance and inclusive finance sectors], [Indicators for outreach, client protection, social responsibility, self-reporting, external audits.], [Widely accepted in the microfinance sector.], [Overlaps with sector-specific stndards like the Universal Standards for Social Performance Management. Gaps in the broader financial inclusion metrics.],
  [Impact Management Project (IMP)], [Provides a consensus on how to measure, manage, and report impacts on people and the planet. Global; comprehensive coverage across multiple sectors and impact themes.], [Five dimensions of impact: what, who, how much, contribution, risk; self-assessment, peer reviews.], [Highly accepted among impact investors and financial institutions.], [Overlaps with IRIS+ and other impact measurement frameworks. Gaps in detailed sector-specific guidelines.],
  [B Impact Assessment (BIA) by B Lab], [Assess social and environmental performance of companies, focusing on governance, workers, community, environment, and customers. Global; socially responsible business across sectors.], [Structured questionnaire, comprehensive assessment, third-party audits for B Corp certification.], [High acceptance among socially responsible businesses and investors.], [Overlaps with ESG frameworks. Gaps include the depth of impact measurement in specific sectors.],
  [Social Return on Investment (SROI)], [Measures social value created by translating social outcomes into monetary values. Global; applicable to community development, education, healthcare, and more.], [Detailed data on inputs, outputs, outcomes, financial proxies, stakeholder engagement, third-party validation.], [Growing acceptance, particularly in the non-profit and public sectors.], [Overlaps with cost-benefit analysis approaches. Gaps include challenges in the assigning monetary values to all social outcomes.],
  [FC’s Operating Principles for Impact Management], [Provides a common understanding of impact investing among market players. Global; applicable at corporate, fund or investment vehicle levels. Consists of 9 principles divided into 5 steps, including Independent Verification], [Annual disclosures, independent verification, payment of a registration fee.], [High acceptance among banks, DFIs, government-backed investment corporations, MDBs, non-profits, asset managers, and investment funds.], [Overlaps with other impact frameworks like GIIN and IMP. Efforts are ongoing to harmonize these principles with other frameworks.],
  [UNEP-FI], [Partnership between the UN and the global financial sector including banks, insurers and investors. Supports PRI, PSI and PRB. Provides tools like Impact Investing Market Map, Corporate Impact Analysis Tool, and Portfolio Impact Analysis Tool for Banks], [Tools use structured assessment and scoring systems based on predefined criteria and KPIs.], [High acceptance in the financial sector, especially among banks and insurers.], [Overlaps with SDG-related frameworks and industry-specific standards. Gaps in comprehensive sector-specific metrics for niche areas.],
  [DCED Standard], [Provides a tool for monitoring and evaluation of development and programmatic projects. Focuses on poverty alleviation through private sector development.], [Structured intervention guide with intervention summary, results chain, reulsts measurement plan, and measurements and calculations.], [Growing acceptance among government, philanthropic, and multilateral agencies working in the private sector development.], [Overlaps with other devleopment-focused frameworks. Gaps in tailored metrics for specific impact investing scenarios.],
  [UNEP-FI Corporate Impact Analysis Tool (CIAT)], [Enables financial institutions to assess the corporate impact of clients and investee companies. Based on the Positive Impact Approach, it is designed for use by larger concerns (Middle Market, Corporates, and MNCs).], [Structured Excel spreadsheet with various tabs explaining methodology and use, scoring system with pre-determined and user-picked weights and guidelines.], [Growing acceptance among large corporations and financial institutions.], [Overlaps with other corporate impact assessment tools. Gaps in tailored metrics for smaller enterprises and specific sectors.],
  [UNEP-FI Portfolio Impact Analysis Tool (PIAT)], [Targets banks, assesses the impact of a given bank’s portfolio, helps banks report and shape their portfolios for positive impact over time. Uses the 22 areas of the Impact Radar.], [Input spreadsheets for Bank Cartography and Country Needs Scores, coupled with predefined impact maps and user inputs to assess positive and negative impacts], [High acceptance among banks, particularly those committed to the PRB framework.], [Overlaps with other banking-specific impact assessment tools. Gaps in comprehensive sector-specific metrics for non-banking financial institutions.],
)
]
= Market growth and reporting trends in sustainable investing
<market-growth-and-reporting-trends-in-sustainable-investing>
#block[
#set enum(numbering: "1.", start: 41)
+ The impact investing market has seen significant growth, with more investors seeking investments that align with their values while offering competitive returns. The growing awareness of global challenges such as climate change, social inequality, and biodiversity loss drives this trend. Pension funds and institutional investors increasingly commit substantial capital to sustainable investments, directing more funds toward energy transition and other impact-focused initiatives. For instance, the California Public Employees’ Retirement System recently announced a \$100 billion commitment toward climate solutions by 2030, moving its portfolio closer to net zero. The New York State Common Retirement Fund also doubled its sustainable investment commitment to \$40 billion to protect state pensions from climate risk. In Europe, many investors commit percentages of their investment portfolio to Sustainable Finance Disclosure Regulation (SFDR) Article 9 funds, which must fulfil specific requirements to be classified as sustainable (#cite(<eisenberg2024>, form: "prose");).

+ The European market has witnessed a rise in specialised impact funds, with established investment firms launching new products to address specific environmental and social challenges. British global investment firm Permira launched its first energy transition fund, and private equity company EQT closed its EQT Future Fund, the most significant impact fund ever raised in private markets. Additionally, private equity firms Ardian, Eurazeo, and Tikehau have launched nature, biodiversity, and other specialised funds focused on clean hydrogen, sustainable agriculture, and energy transition funds in credit, real estate, and other underpenetrated asset classes. As these funds deploy more capital and demonstrate a track record, the industry continues to grow, offering more directed and specific solutions for limited partners. This mobilises substantial capital toward innovative solutions that address pressing environmental and social challenges (#cite(<eisenberg2024>, form: "prose");).

+ Infrastructure investments have also drawn significant attention, with some of the largest US-based general partners and investors focusing on energy transition platforms. Firms like Brookfield, TPG Rise Climate, Apollo, Ares, Blackstone, and KKR have all announced new energy transition funds and commitments to energy transition investments over the past year. This consolidation among general partners is led primarily by large managers responding to their limited partners’ interest in increasing commitments to positive impact through infrastructure and impact investments. According to the GIIN, the five most considerable impact investing general partners accounted for 47% of the total assets under management in the impact investment market. Since last May, several top private equity firms have acquired infrastructure investing capabilities, offering a broader range of strategies to limited partners and bringing new energy transition competencies into their firms (#cite(<eisenberg2024>, form: "prose");).

+ Impact investing in Asia is experiencing significant growth, driven by the need for financial support for expanding businesses and addressing social and environmental challenges. Over the past 15 years, particularly in Southeast Asia, impact investments have surged, with investors committing over two-thirds of the total capital from 2007–2016 in just the last three years (2020-2022). This growth includes a 40% increase in investment and projects compared to the previous three years. Development finance institutions have also maintained annual investments of around US\$2 billion over the past six years. Despite these positive trends, challenges remain, such as bridging the funding gap for early-stage businesses and ensuring investments address issues like greenhouse gas emissions, gender equality, and aging populations. Initiatives like USAID’s ESG program in Vietnam highlight efforts to promote sustainable growth, supporting small and growing businesses crucial to the country’s socio-economic development and environmental sustainability. This expanding market encourages Asian companies to prioritise sustainability and social responsibility, benefiting investors and the broader community (#cite(<richter2023>, form: "prose");).
]

== Evolving dimensions of impact: climate resilience and energy transitions
<evolving-dimensions-of-impact-climate-resilience-and-energy-transitions>
#block[
#set enum(numbering: "1.", start: 45)
+ Market growth trends can give us an understanding of impact dimensions that face increased scrutiny. For example, one significant dimension is the increasing focus on climate resilience and energy transition. With institutional investors like the California Public Employees’ Retirement System committing substantial capital toward climate solutions, there is a clear shift towards investments that offer financial returns and contribute to reducing greenhouse gas emissions and enhancing climate resilience. The emergence of specialised funds dedicated to clean hydrogen, sustainable agriculture, and renewable energy highlights this trend. The commitment to energy transition is further evidenced by the launch of new energy transition funds by firms such as Brookfield, TPG Rise Climate, and Apollo (#cite(<eisenberg2024>, form: "prose");).
]

== Evolving dimensions of impact: social equity and inclusion
<evolving-dimensions-of-impact-social-equity-and-inclusion>
#block[
#set enum(numbering: "1.", start: 46)
+ The alignment of investments with social and equity values is becoming a critical consideration for impact investors. This trend is driven by recognising the importance of addressing social determinants of health and well-being, as well as the need for inclusive economic growth. The rise of Sustainable Finance Disclosure Regulation (SFDR) Article 9 funds in Europe, which require strict adherence to sustainability criteria, reflects a growing demand for investments that promote social equity and address systemic inequalities (#cite(<eisenberg2024>, form: "prose");).

+ Social equity and inclusion have also gained increased scrutiny and importance among impact investors in the Asia-Pacific region. According to the report "Advancing Impact: A Road Map for Social Investing in Asia," several key trends have emerged. There is a growing emphasis on gender equality and women’s empowerment, with investments targeting female entrepreneurs and women-led businesses. Initiatives like Indonesia’s Ojek Syari, a female-only ride-hailing service, illustrate how social investments can address both economic empowerment and safety for women. Additionally, there is a focus on improving health and education outcomes in underserved communities. Investments in nutrition supplement companies in China and educational programs in rural India highlight commitment to addressing fundamental social determinants of health and education disparities. Furthermore, the report emphasises the importance of local context and stakeholder engagement in designing and implementing social investment projects, ensuring that interventions are culturally appropriate and have the support of the communities they aim to serve (#cite(<economist2022>, form: "prose");).

+ Other aspects under the social dimension include the impact of best practices on work environments. Certifications such as "Great Place to Work" and adherence to the Global Compact principles highlight the importance of ethical business practices, employee well-being, and corporate social responsibility. The Multidimensional Poverty Index (MPI) is another critical tool that helps investors assess and address the multifaceted nature of poverty, ensuring that investments contribute to reducing deprivation in areas such as health, education, and living standards. These frameworks and certifications not only improve the quality of work environments but also promote broader social goals, aligning business practices with the pursuit of inclusive and sustainable development.
]

== Integrating holistic ecosystem perspectives
<integrating-holistic-ecosystem-perspectives>
#block[
#set enum(numbering: "1.", start: 49)
+ The need for a comprehensive and interconnected approach to impact assessment has become increasingly critical in recent years. Published reports by the (#cite(<ec2023>, form: "prose");) and the United Nations Office for Disaster Risk Reduction (2023) highlight evolving trends that emphasise integrating a holistic ecosystem perspective within national and international nature targets. Adopting this approach is essential when addressing issues like "impact washing" and enhancing impact measurement and verification processes. Accounting frameworks like Accounting for Nature, the Natural Capital Protocol, Taskforce on Nature-related Financial Disclosures (TNFD), and SEEA emphasise a comprehensive view of ecosystems and stress their interconnectedness, where sustainable development depends on multilayered and interrelated aspects. Such frameworks help identify synergies and trade-offs within ecosystems, ensuring that the diverse services of nature are accurately evaluated and appreciated.

+ Implementing nature-based accounting standards (NCA) is crucial to addressing impact washing. Holistic NCAs utilise detailed measurement standards that capture an aggregate range of environmental impacts. This thorough approach reduces the likelihood of overstating or falsely claiming benefits within impact investment. Impact washing deals with wrongly depicting the effects of investments, often by focusing solely on positive outcomes while neglecting negative impacts. As noted by Bendell (2019), we can only ensure we achieve our intended net societal and environmental benefits if we measure and manage both positive and negative outcomes. This requires a comprehensive impact assessment approach, integrating multi-dimensional metrics to provide an honest and accurate evaluation of investments. By adhering to rigorous, science-based frameworks such as NCAs, stakeholders can maintain transparency and accountability, ensuring that investments contribute genuinely to sustainable development goals and avoid the pitfalls of misleading impact claims. The United Nations Office for Disaster Risk Reduction (2023) report emphasises the importance of recognising co-benefits of nature-based solutions, such as biodiversity conservation, climate regulation, and improved human well-being. This aligns with ecosystem accounting principles, which advocate measuring and valuing multiple ecosystem services based on asset condition and extent assessments to inform decision-making. The implication is that impact assessments should focus on more than just single outcomes and capture the interconnected benefits and trade-offs of environmental investments.

+ Second, stakeholders can avoid impact washing using frameworks like Accounting for Nature, the Natural Capital Protocol, or SEEA by ensuring that all relevant environmental services and ecosystem interconnections are considered through science-based metrics. This prevents the narrow focus on single metrics, which can be misleading, easily manipulated, or diminish impact returns. Instead, the frameworks can provide multi-dimensional views of impact, highlighting both positive outcomes and potential negative trade-offs within ecosystems and, therefore, impact outcomes. The report of the European Commission (2023) emphasises that the credibility and accuracy of impact assessments are heavily dependent on the quality and scientific rigour of the metrics used.

+ Finally, the European Commission’s report (2023) emphasises the importance of considering spatial and temporal scales in impact assessments, acknowledging that nature-based solutions can have varying impacts over different geographic areas and timeframes. Additionally, the report highlights the importance of engaging stakeholders and considering the socio-economic context in designing and assessing nature-based solutions. These considerations stress the need for robust natural accounting frameworks that incorporate and promote continuous monitoring and rigorous assessment to ensure accurate and comprehensive evaluations. Integrating spatial, temporal, and socio-economic factors, nature accounting frameworks can help mitigate impact washing by ensuring that investments are transparently and accurately measured, managed and reported. A comprehensive approach enables the alignment of investment capital more closely with sustainable development goals and international standards, reinforcing genuine positive impacts of impact investments.
]

== Environmental health through sustainable resource management
<environmental-health-through-sustainable-resource-management>
#block[
#set enum(numbering: "1.", start: 53)
+ A well-established dimension in impact investing focuses on efforts to preserve environmental health through sustainable resource management. This dimension encompasses innovation and controls on waste and other sources of pollution, and on water and other resources management, all of which are vital for public health and community well-being. The global increase in waste production has driven the need for advanced waste management solutions, including recycling technologies and waste-to-energy systems. According to the United Nations Environment Programme (UNEP), these innovations help reduce the environmental footprint and promote resource efficiency (UNEP, 2021). Standards and certifications such as Zero Waste to Landfill and tools like LCA (Lifecycle Assessments) are continuously growing in adoption. Similarly, impact investors are increasingly supporting initiatives that tackle other pollution controls, including efforts to reduce air, noise, and water pollution, all linked to severe health issues and environmental degradation (World Health Organization, 2018). Initiatives include those that develop cleaner industrial processes, emissions reduction technologies, and sustainable agricultural practices, among others. These investments are crucial in addressing the adverse effects of pollutants on communities, particularly in densely populated urban areas where air quality concerns are most acute, and on the oceans (Intergovernmental Panel on Climate Change, 2019).

+ Water management also plays a vital role in this dimension, particularly in regions facing water scarcity and contamination challenges. Investments are being directed toward improving water infrastructure, promoting water conservation technologies, and developing systems for better water quality monitoring and management. These efforts are essential in ensuring access to clean and safe water, which is fundamental to public health and economic development (World Resources Institute, 2020). At a corporate scale, frameworks, standards, and even credit schemes such as the Water Footprint, ISO 14046: Environmental Management-Water Footprint, LEED Water Efficiency credits, and the Alliance for Water Stewardship (AWS) Standard are also growing in demand and requirements as water scarcity becomes a more pressing issue globally (#cite(<iso2018>, form: "prose");).

+ The emphasis on environmental health through sustainable resource management is further reflected as a whole in regulatory frameworks and global standards. For instance, the European Union’s Green Deal and Circular Economy Action Plan promote sustainable production and consumption patterns, encouraging investments that align with these goals. Moreover, international agreements like the Paris Agreement highlight the interconnectedness of environmental health and climate action, underscoring the need for integrated approaches to address these issues (European Commission, 2019; United Nations Framework Convention on Climate Change, 2015). In that sense, as previously mentioned, frameworks such as GRI, ISO 14001, and B Corp Certification promote environmental management practices by helping organizations minimize their environmental footprint, comply with applicable laws and regulations, and continually improve their environmental performance (#cite(<gri2021>, form: "prose");).

+ By prioritizing investments in environmental practices such as waste management, pollution control, and water management, impact investors can contribute to significant environmental and social benefits. These include improved public health outcomes, enhanced resilience to environmental changes, and the promotion of sustainable development. As awareness of these issues grows, the demand for solutions that address environmental health and sustainable resource management will likely continue to rise, making this an increasingly important dimension in the impact investment landscape.
]

= Implications for an Australian impact exchange
<implications-for-an-australian-impact-exchange>
#block[
#set enum(numbering: "1.", start: 57)
+ The Australian and global marketplace for nature-related frameworks and standards in undergoing rapid evolution and is far from a state of maturity. Different frameworks and standards have highly heterogenous subject matter scopes and methodological design. This complicates any assessment of trade-offs between different exchange design choices, and creates risks of adverse consequences and path dependencies if premature choices are made to adopt certain methods, frameworks or standards.

+ Another complicating factor is the fundamental uncertainty concerning the scope of assets intended for listing on the proposed AIX. Establishing public exchanges based on verified environmental and social outcomes ("Impact Exchanges") involves careful design choices—about the specific measurement and verification methods, frameworks and standards that determine market disclosures. These design choices depend fundamentally on the scope of assets or instruments that can be traded—for example Impact Exchanges focused on:

  – corporate securities might be best underpinned by holistic disclosure frameworks such as those maintained by the Capitals Coalition (e.g.~the Natural Capital Protocol), or Taskforces for Nature-Related, and Climate-Related Financial Disclosures (TNFD and TCFD respectively).

  – enabling impact investment might be best underpinned by the existing dedicated frameworks such as Global Impact Investing Network’s (GIIN) IRIS+, the Social Return on Investment (SROI), the Social Performance Task Force (SPTF), B Impact Assessment (BIA) by B Lab, and the Impact Management Project (IMP).

  – commodities or real property may be well matched with primary low-level measurement frameworks such as those developed for specific sectoral raw material supply chains (e.g.~apparel, minerals and metals, etc), or environmental characteristics (e.g.~pollution levels, in-situ biodiversity).

+ An alternative approach for AIX to consider is to adopt "meta-standards" that establish key priorities and principles (transparency, methodological replicability, clarity of scope and focus, etc) for disclosure of all nature-related frameworks and standards utilised by assets traded on the exchange. This approach has analogies in other fast-moving sectors (e.g.~telecommunication regulation) and could ensure a balance between flexible innovation, coherent methodological specialisation for specific traded asset classes, and investor requirements.

+ Further research is needed to establish and stress test the specific principles and requirements that would be incorporated into the "meta-standard" for environmental and social metrics. Some candidate principles are summarised below:

  - Principle 1: Traded assets should disclose both their primary environmental and social outcomes (quantified or qualified as appropriate) and the methodological basis for assessing those outcomes.

  - Principle 2: The disclosed methodological basis for disclosure should be compatible with certain quality standards intended to support alignment with general fiduciary principles and Australian consumer regulation. They should:

    - (2A) Transparently document their definitional foundations, input data and assessment methods. Low-level environmental definitions should be aligned with the SEEA as appropriate, in particular to avoid confusion between measurement of environmental stocks (e.g.~the extent and/or condition of specific ecosystem types aligned to the IUCN Global Ecosystem Typology) and flows of goods and services from the environment to the economy (e.g.~carbon sequestration, regulation of waste, flows of raw materials).

    - (2B) Clearly document their functional, geographical and value chain scope coverage (e.g.~1+2 vs 3) and use pre-defined categories aligned to the SEEA and other relevant global statistical standards.

+ We also suggest that a standing technical committee should be incorporated into the governance planning for the AIX with a clear remit to iteratively refine and develop meta-standards concerning social and environmental outcome disclosure, and facilitate pre-competitive dialogue between different frameworks, standards and approaches.

+ A pragmatic alternative to the "meta-standards" approach suggested above would be to establish an Impact Exchange based on clear social and environmental outcome metrics for which there is short-term market demand, regardless of asset class. One advantage of this approach is the ability to generate liquidity and positive margins that could be reinvested into improving and scaling the Impact Exchange. A key risk is that metrics may evolve in response to ad-hoc demand drivers without sufficient attention to generating the coherence, robustness and transparency needed to bring investment in environmental and social outcomes to scale. The fundamental structural deficiencies of both voluntary and statutory carbon markets identified in recent years offers a pertinent cautionary tale.
]

= Appendix
<appendix>
#figure([
#box(image("media/Appendix4.png"))
], caption: figure.caption(
position: bottom, 
[
Overview of ESG Strategies
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#figure([
#box(image("media/Appendix3.png"))
], caption: figure.caption(
position: bottom, 
[
Overview of Impact Investment Strategies
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#figure([
#box(image("media/Appendix2.png"))
], caption: figure.caption(
position: bottom, 
[
Green Finance and Social Finance
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#figure([
#box(image("media/Appendix1.png"))
], caption: figure.caption(
position: bottom, 
[
Governance and Ethical Investing
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)






#bibliography("references.bib")

