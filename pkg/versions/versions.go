// package versions contains constants for the default versions of the
// various SSP sub-components to deploy
package versions

import "fmt"

const (
	KubevirtCommonTemplates   string = "0.4.1"
	KubevirtNodeLabeller      string = "0.0.5"
	KubevirtTemplateValidator string = "0.3.0"
)

// TagForVersion converts the given version in a suitable tag
func TagForVersion(ver string) string {
	return fmt.Sprintf("v%s", ver)
}