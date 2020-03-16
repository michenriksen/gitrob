package core

import "github.com/codeEmitter/gitrob/common"

func GatherTargets(sess *Session) {
	sess.Stats.Status = StatusGathering
	sess.Out.Important("Gathering targets...\n")

	for _, loginOption := range sess.Options.Logins {
		target, err := sess.Client.GetUserOrOrganization(loginOption)
		if err != nil || target == nil {
			sess.Out.Error(" Error retrieving information on %s: %s\n", loginOption, err)
			continue
		}
		sess.Out.Debug("%s (ID: %d) type: %s\n", *target.Login, *target.ID, *target.Type)
		sess.AddTarget(target)
		if *sess.Options.NoExpandOrgs == false && *target.Type == common.TargetTypeOrganization {
			sess.Out.Debug("Gathering members of %s (ID: %d)...\n", *target.Login, *target.ID)
			members, err := sess.Client.GetOrganizationMembers(*target)
			if err != nil {
				sess.Out.Error(" Error retrieving members of %s: %s\n", *target.Login, err)
				continue
			}
			for _, member := range members {
				sess.Out.Debug("Adding organization member %s (ID: %d) to targets\n", *member.Login, *member.ID)
				sess.AddTarget(member)
			}
		}
	}
}
