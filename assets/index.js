const { createContext } = require("tailwindcss/lib/lib/setupContextUtils.js")
const resolveConfig = require("tailwindcss/resolveConfig.js")
const fs = require("fs")
const path = require("path")

function bigSign(bigIntValue) {
  return (bigIntValue > 0n) - (bigIntValue < 0n)
}

function sortOrder([, a], [, z]) {
  if (a === z) return 0
  if (a === null) return -1
  if (z === null) return 1
  return bigSign(a - z)
}

async function loadCustomConfig(configPath) {
  let finalPath = path.isAbsolute(configPath)
    ? configPath
    : path.resolve(path.resolve(process.cwd(), configPath))

  if (!fs.existsSync(finalPath)) {
    const err = new Error("Config file does not exist")
    err.code = 2
    throw err
  }
  const tailwindConfig = require(finalPath)
  return tailwindConfig
}

async function extract(absoluteConfigPath) {
  const customConfig = await loadCustomConfig(absoluteConfigPath)
  const twConfig = await resolveConfig(customConfig)
  const twContext = await createContext(twConfig)

  let allVariants = []
  let allClasses = []
  let classIterator = twContext.candidateRuleMap.keys()

  // first class is an unneeded glob
  classIterator.next()
  let currentClass = classIterator.next()
  while (!currentClass.done) {
    const baseClass = currentClass.value
    const rules = twContext.candidateRuleMap.get(currentClass.value)

    for (let [rule, _] of rules) {
      let potentialClasses = []
      if ("values" in rule.options) {
        const classValues = Object.keys(rule.options.values)
        const supportsNegative = rule.options.supportsNegativeValues

        potentialClasses = classValues.map((value) =>
          value === "DEFAULT" ? baseClass : `${baseClass}-${value}`
        )
        if (supportsNegative) {
          potentialClasses = potentialClasses
            .map((c) => (c.includes("auto") ? c : [`-${c}`, c]))
            .flat()
        }
      } else {
        potentialClasses.push(baseClass)
      }

      allClasses.push(potentialClasses)
      allClasses = allClasses.flat()
    }

    currentClass = classIterator.next()
  }

  // get unique
  allClasses = allClasses.filter((value, index, self) => self.indexOf(value) === index)

  twContext.variantMap.forEach((applyFunc, variant) => allVariants.push([variant, applyFunc[0][0]]))
  allVariants = allVariants
    .sort(sortOrder)
    .map(([className, _]) => className)
    .join("\n")

  let orderedClasses = twContext
    .getClassOrder(allClasses)
    .sort(sortOrder)
    .map(([className, _]) => className)
    .join("\n")

  fs.writeFileSync("_build/classes.txt", orderedClasses)
  fs.writeFileSync("_build/variants.txt", allVariants)
}

let localModules = {
  "tailwindcss/colors": require("tailwindcss/colors"),
  "tailwindcss/plugin": require("tailwindcss/plugin"),
  "tailwindcss/defaultConfig": require("tailwindcss/defaultConfig"),
  "tailwindcss/defaultTheme": require("tailwindcss/defaultTheme"),
  "tailwindcss/resolveConfig": require("tailwindcss/resolveConfig"),
  "@tailwindcss/aspect-ratio": require("@tailwindcss/aspect-ratio"),
  "@tailwindcss/forms": require("@tailwindcss/forms"),
  "@tailwindcss/typography": require("@tailwindcss/typography"),
}

let Module = require("module")
let origRequire = Module.prototype.require
Module.prototype.require = function (id) {
  if (localModules.hasOwnProperty(id)) {
    return localModules[id]
  }
  return origRequire.apply(this, arguments)
}

extract(process.argv[2])
