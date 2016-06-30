
#### [Current]
 * [2c67abe](../../commit/2c67abe) - __(Joshua Hoblitt)__ Merge pull request [#16](../../issues/16) from elisiano/foreman_facts

IPMI facts (rebase only, original PR is [#12](../../issues/12))
 * [7d4ac2e](../../commit/7d4ac2e) - __(Dominique Quatravaux)__ IPMI facts

Expose IPMI facts in a format compatible with RedHat's The Foreman, so
that BMCs appear in its web UI.

Add documentation to README.md

 * [683e0c0](../../commit/683e0c0) - __(Joshua Hoblitt)__ Merge pull request [#13](../../issues/13) from jhoblitt/feature/v2.0.0

Feature/v2.0.0
 * [c52dc2a](../../commit/c52dc2a) - __(Joshua Hoblitt)__ bump version to v2.0.0
 * [bfc0e6a](../../commit/bfc0e6a) - __(Joshua Hoblitt)__ fix rspec puppet 4 compatibility
 * [3123bb9](../../commit/3123bb9) - __(Joshua Hoblitt)__ add Puppet Version Compatibility subsection to README
 * [1e76146](../../commit/1e76146) - __(Joshua Hoblitt)__ update README boilerplate
 * [d2f265d](../../commit/d2f265d) - __(Joshua Hoblitt)__ remove default nodset symlink

To resolve this PMT error:
    Puppet::ModuleTool::Errors::ModuleToolError: Found symlinks. Symlinks in modules are not allowed, please remove them.

 * [1e866b7](../../commit/1e866b7) - __(Joshua Hoblitt)__ add centos 5.11 nodeset
 * [4a1873a](../../commit/4a1873a) - __(Joshua Hoblitt)__ add puppet-blacksmith gem
 * [b37b7a2](../../commit/b37b7a2) - __(Joshua Hoblitt)__ add travis_lint rake target
 * [f230dde](../../commit/f230dde) - __(Joshua Hoblitt)__ add debian 7.8 nodeset
 * [19c3a98](../../commit/19c3a98) - __(Joshua Hoblitt)__ fix trailing whitespace
 * [8dc4b01](../../commit/8dc4b01) - __(Joshua Hoblitt)__ update copyright notice year to 2015
 * [9ccdb91](../../commit/9ccdb91) - __(Joshua Hoblitt)__ add ruby 2.2 to travis matrix
 * [920aaff](../../commit/920aaff) - __(Joshua Hoblitt)__ add :validate to default rake target list
 * [c856b2f](../../commit/c856b2f) - __(Joshua Hoblitt)__ add metadata-json-lint gem

Needed by rake metadata.json validation target.

 * [34304e4](../../commit/34304e4) - __(Joshua Hoblitt)__ set stdlib requirement to 4.6.0
 * [8c2a694](../../commit/8c2a694) - __(Joshua Hoblitt)__ update travis matrix puppet 3.x minimum version to 3.7
 * [e99cd8d](../../commit/e99cd8d) - __(Joshua Hoblitt)__ update rspec-puppet gem version to ~> 2.1.0

For compatibility with puppet 4.0.0

 * [072d233](../../commit/072d233) - __(Joshua Hoblitt)__ add junit/ to .gitiginore

Generated by beaker 5

 * [d53806b](../../commit/d53806b) - __(Joshua Hoblitt)__ add puppet 4.0 to travis matrix
 * [2540953](../../commit/2540953) - __(Joshua Hoblitt)__ remove puppet 2.7 from travis matrix

4.0.0 has been released; support major release -1

 * [9db5563](../../commit/9db5563) - __(Joshua Hoblitt)__ update beaker nodesets to use current chef/bento boxes
 * [e89d202](../../commit/e89d202) - __(Joshua Hoblitt)__ add log/ to .gitignore

Generated by beaker during execution.

 * [d5bb67e](../../commit/d5bb67e) - __(Joshua Hoblitt)__ pin rspec on Ruby 1.8.7 (rspec/rspec-core[#1864](../../issues/1864))
 * [25f6bb1](../../commit/25f6bb1) - __(Joshua Hoblitt)__ use rspec-puppet 2.0.0 from gems instead of git
 * [c1aac2a](../../commit/c1aac2a) - __(Joshua Hoblitt)__ add FACTER_GEM_VERSION to Gemfile
 * [76feb38](../../commit/76feb38) - __(Joshua Hoblitt)__ convert Modulefile to metadata.json
 * [cf8aea0](../../commit/cf8aea0) - __(Joshua Hoblitt)__ update spec_helper_acceptance to use #puppet_module_install

Instead of custom scp logic

 * [1c982ef](../../commit/1c982ef) - __(Joshua Hoblitt)__ change nodeset default to centos-65-x64
 * [0790875](../../commit/0790875) - __(Joshua Hoblitt)__ add beaker nodeset for centos 7
 * [afa2bee](../../commit/afa2bee) - __(Joshua Hoblitt)__ add beaker support
 * [b24fa45](../../commit/b24fa45) - __(Joshua Hoblitt)__ enable travis container based builds
 * [6984ec8](../../commit/6984ec8) - __(Joshua Hoblitt)__ update rspec-puppet to v2.0.0 git tag
 * [8d66569](../../commit/8d66569) - __(Joshua Hoblitt)__ tidy Gemfile formatting
 * [ec06fc6](../../commit/ec06fc6) - __(Joshua Hoblitt)__ fail on linter warnings
 * [cf8ef28](../../commit/cf8ef28) - __(Joshua Hoblitt)__ Merge pull request [#11](../../issues/11) from bodgit/watchdog

Add support for enabling the IPMI watchdog
 * [eade2fe](../../commit/eade2fe) - __(Matt Dainty)__ Add support for enabling the IPMI watchdog
 * [73cf7ef](../../commit/73cf7ef) - __(Joshua Hoblitt)__ Merge pull request [#10](../../issues/10) from jhoblitt/feature/future_parser

Feature/future parser
 * [52e33e1](../../commit/52e33e1) - __(Joshua Hoblitt)__ update rspec-puppet matchers

Convert from #include_class to #contain_class

 * [f460ee9](../../commit/f460ee9) - __(Joshua Hoblitt)__ add future parser to travis matrix
 * [022b877](../../commit/022b877) - __(Joshua Hoblitt)__ Merge pull request [#9](../../issues/9) from jhoblitt/feature/copyright_consolidation

consolidate all copyright notices into LICENSE file

#### v1.2.0
 * [d910696](../../commit/d910696) - __(Joshua Hoblitt)__ consolidate all copyright notices into LICENSE file
 * [a7a628a](../../commit/a7a628a) - __(Joshua Hoblitt)__ Merge pull request [#8](../../issues/8) from jhoblitt/feature/v1.2.0

Feature/v1.2.0
 * [88b1b24](../../commit/88b1b24) - __(Joshua Hoblitt)__ bump version to v1.2.0
 * [5b5770f](../../commit/5b5770f) - __(Joshua Hoblitt)__ fix linter warnings
 * [0d2f8ef](../../commit/0d2f8ef) - __(Joshua Hoblitt)__ update README format
 * [a2f9824](../../commit/a2f9824) - __(Joshua Hoblitt)__ update puppet versions in travis matrix
 * [3c283b1](../../commit/3c283b1) - __(Joshua Hoblitt)__ add el7.x to README platforms list
 * [d7b6c5f](../../commit/d7b6c5f) - __(Joshua Hoblitt)__ add `:require` option to all Gemfile entries
 * [af79b53](../../commit/af79b53) - __(Joshua Hoblitt)__ update .gitignore
 * [9bd46bd](../../commit/9bd46bd) - __(Joshua Hoblitt)__ update copyright notice year to 2014
 * [edf951c](../../commit/edf951c) - __(Joshua Hoblitt)__ Merge pull request [#7](../../issues/7) from razorsedge/support_el7

Added support for EL7.
 * [3fe4023](../../commit/3fe4023) - __(Michael Arnold)__ Make the spec tests pass.

Commented out all the "should include_class" stanzas.  This should make
Travis-CI happy.

 * [d6f934f](../../commit/d6f934f) - __(Michael Arnold)__ Added support for EL7.
 * [2dae883](../../commit/2dae883) - __(Joshua Hoblitt)__ fix README ToC

#### v1.1.1
 * [26e1430](../../commit/26e1430) - __(Joshua Hoblitt)__ bump version to v1.1.1
 * [de20f48](../../commit/de20f48) - __(Joshua Hoblitt)__ update README param docs
 * [4e07c04](../../commit/4e07c04) - __(Joshua Hoblitt)__ reduce stdlib requirement to 3.0.0
 * [0a3be5b](../../commit/0a3be5b) - __(Joshua Hoblitt)__ add puppet 3.3.0 to travis test matrix
 * [c2a54cb](../../commit/c2a54cb) - __(Joshua Hoblitt)__ add GFMD highlighting to README
 * [aafd0c8](../../commit/aafd0c8) - __(Joshua Hoblitt)__ fix README markdown typo

#### v1.1.0
 * [b83bdd7](../../commit/b83bdd7) - __(Joshua Hoblitt)__ bump version to v1.1.0
 * [8f04955](../../commit/8f04955) - __(Joshua Hoblitt)__ Merge pull request [#5](../../issues/5) from jhoblitt/service_control

split ipmi::service class into ipmi::service::{ipmi,ipmievd)
 * [47cc455](../../commit/47cc455) - __(Joshua Hoblitt)__ split ipmi::service class into ipmi::service::{ipmi,ipmievd)
 * [7f1d5c3](../../commit/7f1d5c3) - __(Joshua Hoblitt)__ puppet-lint should ignore pkg/**

#### v1.0.1
 * [2821421](../../commit/2821421) - __(Joshua Hoblitt)__ bump version to v1.0.1
 * [4f19e76](../../commit/4f19e76) - __(Joshua Hoblitt)__ Merge pull request [#4](../../issues/4) from jhoblitt/remove_lsb_facts

remove usage of $::lsbmajdistrelease fact
 * [23c2227](../../commit/23c2227) - __(Joshua Hoblitt)__ remove usage of $::lsbmajdistrelease fact

Instead use $::operatingsystemmajrelease as this fact is not dependant on
redhat-lsb being present on the system.

 * [95c5d0f](../../commit/95c5d0f) - __(Joshua Hoblitt)__ fix ugly typo in ipmi::service tests
 * [f76e51f](../../commit/f76e51f) - __(Joshua Hoblitt)__ validate `$start_ipmievd` param to classes `ipmi` & `ipmi::service`
 * [2b6de1a](../../commit/2b6de1a) - __(Joshua Hoblitt)__ Merge pull request [#2](../../issues/2) from razorsedge/ipmievd

Support for ipmievd.
 * [a3922d2](../../commit/a3922d2) - __(Michael Arnold)__ Advanced configuration of ipmievd service.
 * [a99cf85](../../commit/a99cf85) - __(Michael Arnold)__ Basic addition of ipmievd service.

#### v1.0.0
 * [efc47e5](../../commit/efc47e5) - __(Joshua Hoblitt)__ refactor module structure

* split ipmi::install into ipmi::{install,params}
* base class inherits ipmi::params
* contain subclasses in ipmi base class
* comprehensive test coverage

 * [7534ba8](../../commit/7534ba8) - __(Joshua Hoblitt)__ fix README ToC formatting
 * [9defe3b](../../commit/9defe3b) - __(Joshua Hoblitt)__ update README formatting
 * [8128871](../../commit/8128871) - __(Joshua Hoblitt)__ fix linter warnings
 * [3acd51d](../../commit/3acd51d) - __(Joshua Hoblitt)__ Merge puppet-module_skel
 * [fd0a998](../../commit/fd0a998) - __(Joshua Hoblitt)__ first commit