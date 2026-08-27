//
//  APIBookInternalAuthor.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 11/12/2025.
//  Copyright © 2025 Kneady Technologies.
//

import Foundation

enum APIBookInternalAuthor: String, CaseIterable {

    // MARK: - Legacy Romance (32)
    case isabellaHart // NSFW
    case claireRavenwood // NSFW
    case laurenVale // NSFW
    case graceEllington // NSFW
    case scarlettDawes // NSFW
    case blairKensington // NSFW
    case ivyLockhart // NSFW
    case zoeCarradine // NSFW
    case savannahPrescott // NSFW
    case daphneSterling // NSFW
    case naomiBlaine // NSFW
    case siennaRourke // NSFW
    case tessaCalhoun // NSFW
    case jadeWhitaker // NSFW
    case summerCalloway // NSFW
    case brooklynHarlow // NSFW
    case sophieHawthorne
    case juliaRivers
    case evaMarlowe
    case miaHarrington
    case hannahCole
    case ameliaWhitmore
    case jenniferCollins
    case michaelRoberts
    case stephanieClark
    case christopherLewis
    case amandaWalker
    case danielHall
    case melissaYoung
    case matthewAllen
    case christinaKing
    case andrewScott

    // MARK: - Legacy Thriller (20)
    case vincentKane
    case harperCross
    case sloaneMercer
    case felixDrake
    case marloweSteele
    case reedDonovan
    case camdenPrice
    case ardenSlate
    case bryceHollis
    case jacobStroud
    case ryanFoster
    case kimberlyBarnes
    case stevenHoward
    case nicoleWard
    case patrickTorres
    case heatherGray
    case brandonRoss
    case courtneyPrice
    case derekSanders
    case vanessaPowell

    // MARK: - Legacy Mystery (20)
    case eleanorQuinn
    case jasperHolt
    case margaretPierce
    case desmondGrey
    case lilaWinslow
    case helenLocke
    case martinEllery
    case claireRowland
    case trevorSutton
    case noraBishop
    case katherineMorgan
    case williamCooper
    case samanthaReed
    case jonathanBailey
    case natalieRivera
    case gregoryBell
    case allisonMurphy
    case timothyCox
    case danielleRichardson
    case adamHoward

    // MARK: - Legacy Horror (20)
    case damianCrowe
    case sylviaBlackwood
    case thomasMarlow
    case ravenLeigh
    case lucindaParker
    case gideonHale
    case marthaCrane
    case conradBishop
    case eliseRadcliffe
    case peterGraves
    case michelleCarter
    case benjaminStewart
    case ashleyMorris
    case joshuaRogers
    case brittanyGriffin
    case kennethHayes
    case lindseyPalmer
    case randyHughes
    case tiffanyBarnes
    case craigColeman

    // MARK: - Legacy Fantasy (20)
    case alexanderStorm
    case sarahDempsey
    case eamonTurner
    case lydiaWren
    case calvinFrost
    case nathanielRowe
    case juliaAshford
    case callumHawke
    case eliseCarroway
    case marcusThornbridge
    case angelaNelson
    case jeffreyPeterson
    case dianaButler
    case scottBrooks
    case rebeccaKelly
    case travisSanders
    case erinWatson
    case aaronBrooks
    case cynthiaPerry
    case douglasLong

    // MARK: - Legacy Science Fiction (20)
    case owenVega
    case noraSinclair
    case cassianRyder
    case elizaQuinn
    case juneTrelawney
    case damonReeves
    case natalieBrooks
    case griffinShaw
    case ellaMaddox
    case lucasHartwell
    case christineRussell
    case philipGriffin
    case amberPatterson
    case russellColeman
    case monicaFoster
    case bradleyWard
    case crystalHayes
    case dustinShaw
    case catherineRivera
    case toddPalmer

    // MARK: - Legacy Historical (20)
    case beatriceHawthorne
    case edmundFairfax
    case ceciliaMonroe
    case thaddeusLangley
    case arabellaCrane
    case henryBlackwell
    case florenceAlder
    case frederickBowman
    case adelineSomerset
    case geoffreyTurnbull
    case virginiaHarper
    case kennethSullivan
    case elizabethRussell
    case ronaldGraham
    case margaretStevens
    case eugeneCrawford
    case dorothyNelson
    case haroldFisher
    case ruthPeterson
    case francisReynolds

    // MARK: - Legacy Drama (20)
    case madelineAvery
    case simonCalder
    case vivienneClarke
    case theodoreHensley
    case rosalindKeene
    case julianMerrick
    case ellaRowe
    case michaelHartford
    case graceLennox
    case harveyFielding
    case sharonMartinez
    case garyHenderson
    case karenPhillips
    case larryCampbell
    case sandraRichardson
    case jerryButler
    case deborahParker
    case dennisEvans
    case nancyEdwards
    case raymondCollins

    // MARK: - Legacy Adventure (20)
    case finnGallagher
    case islaQuinn
    case dashiellHunt
    case tessaDrake
    case ronanWilde
    case carterMason
    case lilyAlden
    case jasperKeaton
    case seanBriggs
    case hollyCarrington
    case tylerGrant
    case morganEllis
    case jakeHarrison
    case brookeChapman
    case coleSpencer
    case sierraLawrence
    case blakeMarshall
    case paigeDawson
    case wyattPorter
    case kendallRussell

    // MARK: - Legacy Comedy (20)
    case poppyWillis
    case maxChandler
    case jasperLark
    case olivePenrose
    case felixGoodwin
    case lunaParsons
    case charlieMiller
    case meganFarley
    case oscarHughes
    case rubyPritchard
    case caseyJordan
    case rileyMorgan
    case drewPatterson
    case jamieReynolds
    case taylorHudson
    case morganBlake
    case quinnFitzgerald
    case averyChambers
    case jordanSpencer
    case rileyDonovan

    // MARK: - Legacy Kids (10)
    case sarahMitchell
    case davidCampbell
    case amyRobinson
    case jasonTaylor
    case rachelAnderson
    case kevinMartin
    case lauraBennett
    case brianThompson
    case jessicaWilson
    case markDavis

    // MARK: - Active Romance (37)
    case annaBennett
    case claireMorrison
    case emilyParker
    case rachelConnelly
    case sophieMerritt
    case meganHartley
    case elenaBrooks
    case hannahMonroe
    case laurenBishop
    case oliviaPerry
    case juliaConrad
    case erinSullivan
    case amyRowe
    case naomiKeller
    case victoriaLane
    case graceNolan
    case claraWeston
    case danielleFoster
    case abigailMorris
    case katherineEllis
    case lilySutton
    case christinaHayes
    case mollyFarrell
    case sarahJennings
    case beccaMorgan
    case courtneyBates
    case chelseaPorter
    case alexandraWalsh
    case nicholasCole
    case benjaminCarter
    case adrianMiller
    case seanMurphy
    case emmaBrooks
    case eliseTurner
    case natalieJames
    case kimberlyLane
    case aliciaMoore

    // MARK: - Active Thriller (25)
    case lauraKeen
    case michaelTrent
    case sarahDalton
    case peterCollins
    case erinCrossley
    case jasonWalsh
    case nicoleBarrett
    case adamKeane
    case meganHolt
    case brianDoyle
    case karenLynch
    case danielPhelps
    case allisonBryant
    case markSullivan
    case rachelNorris
    case kevinFarrell
    case laurenDunn
    case scottBrennan
    case taraBishop
    case christopherLarsen
    case dylanHayes
    case monicaBlake
    case victorNolan
    case aishaRoberts
    case landonBurke

    // MARK: - Active Mystery (25)
    case helenAvery
    case robertKeller
    case lisaMontgomery
    case susanWhitaker
    case martinByrne
    case paulWarren
    case carolineHart
    case davidPierce
    case angelaMoore
    case julieBaxter
    case henryWalters
    case melanieCross
    case stephenGibson
    case aliceDunn
    case patrickConroy
    case ninaWalsh
    case georgeHarmon
    case claireBecker
    case timothyHale
    case monicaReid
    case eliseBarker
    case malcolmDoyle
    case ireneKelly
    case lauraJennings
    case peterWalsh

    // MARK: - Active Horror (25)
    case andrewKerr
    case roseMadden
    case philipCrowley
    case juliaKerrigan
    case seanAbbott
    case teresaNolan
    case ianPritchard
    case lindaHarper
    case gregMathews
    case sabrinaFrost
    case peterMadden
    case elizabethDean
    case colinShaw
    case marianneCole
    case arthurBoyd
    case rachelDevlin
    case samuelGreer
    case janetLowell
    case milesDonahue
    case catherineByrne
    case martaDoyle
    case ronaldPike
    case juliaGraves
    case simonWalsh
    case kennethBlair

    // MARK: - Active Fantasy (25)
    case hannahKerr
    case adrianDoyle
    case claireTobin
    case evelynHart
    case lauraDonnelly
    case matthewQuinn
    case naomiClarke
    case owenKavanagh
    case elizabethKeary
    case danielFinn
    case meganTierney
    case patrickHoran
    case annaLarkin
    case nicholasReid
    case siobhanCasey
    case colmBarrett
    case rachelKirby
    case julianFarrell
    case maeveSullivan
    case roisinBlake
    case selinaBrooks
    case farahMalik
    case jonahBell
    case ameliaStone
    case devSharma

    // MARK: - Active Science Fiction (25)
    case alanPark
    case michelleNguyen
    case davidShah
    case juliaKim
    case kevinPatel
    case rachelChen
    case brianMorris
    case erinWalker
    case jamesKwan
    case seanWalters
    case nathanSato
    case noahBrooks
    case isaacLawson
    case blakeWard
    case ethanMora
    case jordanReed
    case danielMorgan
    case jackHarrison
    case ryanTorres
    case jackGriffin
    case raviBanerjee
    case anikaRao
    case jonasPatel
    case samiraKhan
    case luisOrtega

    // MARK: - Active Historical (30)
    case edithBennett
    case charlesAshby
    case margaretHollis
    case arthurSinclair
    case helenCarr
    case janeEllison
    case thomasWinters
    case maryKendall
    case edwardBarker
    case louisaGrant
    case claraWells
    case frederickHarding
    case aliceDurham
    case francesWilcox
    case samuelPritchard
    case evelynTurner
    case robertGodwin
    case beatriceCaldwell
    case georgeSutton
    case harrietDawson
    case amaraFreeman
    case malikToussaint
    case zoraAdebayo
    case niaJohnson
    case isaiahBrooks
    case jacquelineEllis
    case dariusKing
    case estherColeman
    case naomiLewis
    case violaJackson

    // MARK: - Active Drama (25)
    case annePorter
    case lisaConway
    case michaelLeary
    case susanBarlow
    case peterEmerson
    case katherineDoyle
    case jamesFarmer
    case helenNorris
    case adamBennett
    case clareHenderson
    case timothyRourke
    case deborahLevin
    case martinFoley
    case sarahKemp
    case emmaDalton
    case gregoryMiles
    case lauraWhitman
    case brianKerr
    case danielleStern
    case josephMadden
    case aliciaRomero
    case janineCooper
    case melissaKing
    case patrickBell
    case ireneFlores

    // MARK: - Active Adventure (25)
    case nathanBrooks
    case ellaSayers
    case jamesDelaney
    case claireIrwin
    case hannahCollier
    case patrickFlynn
    case zoeMarshall
    case connorReid
    case meganDoyle
    case lukeBennett
    case saraKeating
    case dylanFoster
    case erinNash
    case owenMurphy
    case benTurner
    case katieWalsh
    case roryMadden
    case paulaGreene
    case seanCarver
    case lucyHolland
    case diegoRamos
    case natalieScott
    case beatrizLopez
    case malcolmHayes
    case kendraLewis

    // MARK: - Active Comedy (25)
    case aliceParker
    case carolineFox
    case joshCarter
    case mollyAdams
    case peterNolan
    case hannahFisher
    case danielKirby
    case rachelMills
    case owenAbbott
    case lauraDean
    case jamieBarker
    case emilySims
    case matthewRowan
    case ninaFarrell
    case chrisMurray
    case sophieWells
    case markEllis
    case beccaHoward
    case tomHarper
    case lucyGreene
    case benPritchard
    case kellyNewman
    case luisGomez
    case janetCooper
    case heatherBell

    // MARK: - Active Kids (15)
    case susanParker
    case danielMoore
    case helenCarter
    case michaelBenson
    case rachelDavis
    case andrewHill
    case jennyCollins
    case paulMartin
    case lucyWalker
    case benTaylor
    case ellaMorgan
    case emmaBailey
    case leoFoster
    case graceHughes
    case zoeBailey

    private struct GenreRoster {
        let active: [APIBookInternalAuthor]
        let legacy: [APIBookInternalAuthor]
    }

    private static let genreRosters: [BookInternalGenre: GenreRoster] = [
        .romance: GenreRoster(
            active: [
                .annaBennett, .claireMorrison, .emilyParker, .rachelConnelly,
                .sophieMerritt, .meganHartley, .elenaBrooks, .hannahMonroe,
                .laurenBishop, .oliviaPerry, .juliaConrad, .erinSullivan,
                .amyRowe, .naomiKeller, .victoriaLane, .graceNolan,
                .claraWeston, .danielleFoster, .abigailMorris, .katherineEllis,
                .lilySutton, .christinaHayes, .mollyFarrell, .sarahJennings,
                .beccaMorgan, .courtneyBates, .chelseaPorter, .alexandraWalsh,
                .nicholasCole, .benjaminCarter, .adrianMiller, .seanMurphy,
                .emmaBrooks, .eliseTurner, .natalieJames, .kimberlyLane,
                .aliciaMoore
            ],
            legacy: [
                .isabellaHart, .claireRavenwood, .laurenVale, .graceEllington,
                .scarlettDawes, .blairKensington, .ivyLockhart, .zoeCarradine,
                .savannahPrescott, .daphneSterling, .naomiBlaine, .siennaRourke,
                .tessaCalhoun, .jadeWhitaker, .summerCalloway, .brooklynHarlow,
                .sophieHawthorne, .juliaRivers, .evaMarlowe, .miaHarrington,
                .hannahCole, .ameliaWhitmore, .jenniferCollins, .michaelRoberts,
                .stephanieClark, .christopherLewis, .amandaWalker, .danielHall,
                .melissaYoung, .matthewAllen, .christinaKing, .andrewScott
            ]
        ),
        .thriller: GenreRoster(
            active: [
                .lauraKeen, .michaelTrent, .sarahDalton, .peterCollins,
                .erinCrossley, .jasonWalsh, .nicoleBarrett, .adamKeane,
                .meganHolt, .brianDoyle, .karenLynch, .danielPhelps,
                .allisonBryant, .markSullivan, .rachelNorris, .kevinFarrell,
                .laurenDunn, .scottBrennan, .taraBishop, .christopherLarsen,
                .dylanHayes, .monicaBlake, .victorNolan, .aishaRoberts,
                .landonBurke
            ],
            legacy: [
                .vincentKane, .harperCross, .sloaneMercer, .felixDrake,
                .marloweSteele, .reedDonovan, .camdenPrice, .ardenSlate,
                .bryceHollis, .jacobStroud, .ryanFoster, .kimberlyBarnes,
                .stevenHoward, .nicoleWard, .patrickTorres, .heatherGray,
                .brandonRoss, .courtneyPrice, .derekSanders, .vanessaPowell
            ]
        ),
        .mystery: GenreRoster(
            active: [
                .helenAvery, .robertKeller, .lisaMontgomery, .susanWhitaker,
                .martinByrne, .paulWarren, .carolineHart, .davidPierce,
                .angelaMoore, .julieBaxter, .henryWalters, .melanieCross,
                .stephenGibson, .aliceDunn, .patrickConroy, .ninaWalsh,
                .georgeHarmon, .claireBecker, .timothyHale, .monicaReid,
                .eliseBarker, .malcolmDoyle, .ireneKelly, .lauraJennings,
                .peterWalsh
            ],
            legacy: [
                .eleanorQuinn, .jasperHolt, .margaretPierce, .desmondGrey,
                .lilaWinslow, .helenLocke, .martinEllery, .claireRowland,
                .trevorSutton, .noraBishop, .katherineMorgan, .williamCooper,
                .samanthaReed, .jonathanBailey, .natalieRivera, .gregoryBell,
                .allisonMurphy, .timothyCox, .danielleRichardson, .adamHoward
            ]
        ),
        .horror: GenreRoster(
            active: [
                .andrewKerr, .roseMadden, .philipCrowley, .juliaKerrigan,
                .seanAbbott, .teresaNolan, .ianPritchard, .lindaHarper,
                .gregMathews, .sabrinaFrost, .peterMadden, .elizabethDean,
                .colinShaw, .marianneCole, .arthurBoyd, .rachelDevlin,
                .samuelGreer, .janetLowell, .milesDonahue, .catherineByrne,
                .martaDoyle, .ronaldPike, .juliaGraves, .simonWalsh,
                .kennethBlair
            ],
            legacy: [
                .damianCrowe, .sylviaBlackwood, .thomasMarlow, .ravenLeigh,
                .lucindaParker, .gideonHale, .marthaCrane, .conradBishop,
                .eliseRadcliffe, .peterGraves, .michelleCarter, .benjaminStewart,
                .ashleyMorris, .joshuaRogers, .brittanyGriffin, .kennethHayes,
                .lindseyPalmer, .randyHughes, .tiffanyBarnes, .craigColeman
            ]
        ),
        .fantasy: GenreRoster(
            active: [
                .hannahKerr, .adrianDoyle, .claireTobin, .evelynHart,
                .lauraDonnelly, .matthewQuinn, .naomiClarke, .owenKavanagh,
                .elizabethKeary, .danielFinn, .meganTierney, .patrickHoran,
                .annaLarkin, .nicholasReid, .siobhanCasey, .colmBarrett,
                .rachelKirby, .julianFarrell, .maeveSullivan, .roisinBlake,
                .selinaBrooks, .farahMalik, .jonahBell, .ameliaStone,
                .devSharma
            ],
            legacy: [
                .alexanderStorm, .sarahDempsey, .eamonTurner, .lydiaWren,
                .calvinFrost, .nathanielRowe, .juliaAshford, .callumHawke,
                .eliseCarroway, .marcusThornbridge, .angelaNelson, .jeffreyPeterson,
                .dianaButler, .scottBrooks, .rebeccaKelly, .travisSanders,
                .erinWatson, .aaronBrooks, .cynthiaPerry, .douglasLong
            ]
        ),
        .scienceFiction: GenreRoster(
            active: [
                .alanPark, .michelleNguyen, .davidShah, .juliaKim,
                .kevinPatel, .rachelChen, .brianMorris, .erinWalker,
                .jamesKwan, .seanWalters, .nathanSato, .noahBrooks,
                .isaacLawson, .blakeWard, .ethanMora, .jordanReed,
                .danielMorgan, .jackHarrison, .ryanTorres, .jackGriffin,
                .raviBanerjee, .anikaRao, .jonasPatel, .samiraKhan,
                .luisOrtega
            ],
            legacy: [
                .owenVega, .noraSinclair, .cassianRyder, .elizaQuinn,
                .juneTrelawney, .damonReeves, .natalieBrooks, .griffinShaw,
                .ellaMaddox, .lucasHartwell, .christineRussell, .philipGriffin,
                .amberPatterson, .russellColeman, .monicaFoster, .bradleyWard,
                .crystalHayes, .dustinShaw, .catherineRivera, .toddPalmer
            ]
        ),
        .historical: GenreRoster(
            active: [
                .edithBennett, .charlesAshby, .margaretHollis, .arthurSinclair,
                .helenCarr, .janeEllison, .thomasWinters, .maryKendall,
                .edwardBarker, .louisaGrant, .claraWells, .frederickHarding,
                .aliceDurham, .francesWilcox, .samuelPritchard, .evelynTurner,
                .robertGodwin, .beatriceCaldwell, .georgeSutton, .harrietDawson,
                .amaraFreeman, .malikToussaint, .zoraAdebayo, .niaJohnson,
                .isaiahBrooks, .jacquelineEllis, .dariusKing, .estherColeman,
                .naomiLewis, .violaJackson
            ],
            legacy: [
                .beatriceHawthorne, .edmundFairfax, .ceciliaMonroe, .thaddeusLangley,
                .arabellaCrane, .henryBlackwell, .florenceAlder, .frederickBowman,
                .adelineSomerset, .geoffreyTurnbull, .virginiaHarper, .kennethSullivan,
                .elizabethRussell, .ronaldGraham, .margaretStevens, .eugeneCrawford,
                .dorothyNelson, .haroldFisher, .ruthPeterson, .francisReynolds
            ]
        ),
        .drama: GenreRoster(
            active: [
                .annePorter, .lisaConway, .michaelLeary, .susanBarlow,
                .peterEmerson, .katherineDoyle, .jamesFarmer, .helenNorris,
                .adamBennett, .clareHenderson, .timothyRourke, .deborahLevin,
                .martinFoley, .sarahKemp, .emmaDalton, .gregoryMiles,
                .lauraWhitman, .brianKerr, .danielleStern, .josephMadden,
                .aliciaRomero, .janineCooper, .melissaKing, .patrickBell,
                .ireneFlores
            ],
            legacy: [
                .madelineAvery, .simonCalder, .vivienneClarke, .theodoreHensley,
                .rosalindKeene, .julianMerrick, .ellaRowe, .michaelHartford,
                .graceLennox, .harveyFielding, .sharonMartinez, .garyHenderson,
                .karenPhillips, .larryCampbell, .sandraRichardson, .jerryButler,
                .deborahParker, .dennisEvans, .nancyEdwards, .raymondCollins
            ]
        ),
        .adventure: GenreRoster(
            active: [
                .nathanBrooks, .ellaSayers, .jamesDelaney, .claireIrwin,
                .hannahCollier, .patrickFlynn, .zoeMarshall, .connorReid,
                .meganDoyle, .lukeBennett, .saraKeating, .dylanFoster,
                .erinNash, .owenMurphy, .benTurner, .katieWalsh,
                .roryMadden, .paulaGreene, .seanCarver, .lucyHolland,
                .diegoRamos, .natalieScott, .beatrizLopez, .malcolmHayes,
                .kendraLewis
            ],
            legacy: [
                .finnGallagher, .islaQuinn, .dashiellHunt, .tessaDrake,
                .ronanWilde, .carterMason, .lilyAlden, .jasperKeaton,
                .seanBriggs, .hollyCarrington, .tylerGrant, .morganEllis,
                .jakeHarrison, .brookeChapman, .coleSpencer, .sierraLawrence,
                .blakeMarshall, .paigeDawson, .wyattPorter, .kendallRussell
            ]
        ),
        .comedy: GenreRoster(
            active: [
                .aliceParker, .carolineFox, .joshCarter, .mollyAdams,
                .peterNolan, .hannahFisher, .danielKirby, .rachelMills,
                .owenAbbott, .lauraDean, .jamieBarker, .emilySims,
                .matthewRowan, .ninaFarrell, .chrisMurray, .sophieWells,
                .markEllis, .beccaHoward, .tomHarper, .lucyGreene,
                .benPritchard, .kellyNewman, .luisGomez, .janetCooper,
                .heatherBell
            ],
            legacy: [
                .poppyWillis, .maxChandler, .jasperLark, .olivePenrose,
                .felixGoodwin, .lunaParsons, .charlieMiller, .meganFarley,
                .oscarHughes, .rubyPritchard, .caseyJordan, .rileyMorgan,
                .drewPatterson, .jamieReynolds, .taylorHudson, .morganBlake,
                .quinnFitzgerald, .averyChambers, .jordanSpencer, .rileyDonovan
            ]
        ),
        .kids: GenreRoster(
            active: [
                .susanParker, .danielMoore, .helenCarter, .michaelBenson,
                .rachelDavis, .andrewHill, .jennyCollins, .paulMartin,
                .lucyWalker, .benTaylor, .ellaMorgan, .emmaBailey,
                .leoFoster, .graceHughes, .zoeBailey
            ],
            legacy: [
                .sarahMitchell, .davidCampbell, .amyRobinson, .jasonTaylor,
                .rachelAnderson, .kevinMartin, .lauraBennett, .brianThompson,
                .jessicaWilson, .markDavis
            ]
        )
    ]

    // MARK: - authorsForGenre
    static func authorsForGenre(_ genre: BookInternalGenre) -> [APIBookInternalAuthor] {
        genreRosters[genre]?.active ?? []
    }

    static func authorsForGenre(_ genre: BookInternalGenre, preserving preservedAuthor: APIBookInternalAuthor?) -> [APIBookInternalAuthor] {
        var authors = authorsForGenre(genre)

        if let preservedAuthor,
           !authors.contains(preservedAuthor) {
            authors.append(preservedAuthor)
        }

        return authors
    }

    // MARK: - displayName
    var displayName: String {
        Self.displayName(for: rawValue)
    }

    // MARK: - init(displayName:)
    init?(displayName: String) {
        guard let match = APIBookInternalAuthor.allCases.first(where: { $0.displayName == displayName }) else {
            return nil
        }

        self = match
    }

    private static func displayName(for rawValue: String) -> String {
        var words: [String] = []
        var currentWord = ""

        for character in rawValue {
            if isUppercase(character),
               !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = String(character)
            } else {
                currentWord.append(character)
            }
        }

        if !currentWord.isEmpty {
            words.append(currentWord)
        }

        return words
            .map { word in
                guard let firstCharacter = word.first else { return word }
                return firstCharacter.uppercased() + String(word.dropFirst())
            }
            .joined(separator: " ")
    }

    private static func isUppercase(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(CharacterSet.uppercaseLetters.contains)
    }
}
