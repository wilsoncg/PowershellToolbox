#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client")

$tfsReferencedAssemblies = (
"Microsoft.TeamFoundation.Client, Version=12.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a",
"Microsoft.TeamFoundation.VersionControl.Client, Version=12.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
)

$source = @"
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.VersionControl.Client;
using System.Linq;
using System;

namespace TfsTools 
{
	public class LockedFiles
	{
		public static object[] GetLockedFiles(string serverUrl, string serverPath)
		{
			var uri = new System.Uri(serverUrl);
			TfsTeamProjectCollection tfs = new TfsTeamProjectCollection(uri);
			VersionControlServer vcServer = (VersionControlServer)tfs.GetService(typeof(VersionControlServer));

			PendingSet[] pendingSets = vcServer.QueryPendingSets(
			  new string[] { serverPath }, 
			  RecursionType.Full, 
			  null, 
			  null);
			
			return pendingSets.SelectMany(cs => cs.PendingChanges
			.Where(pc => pc.IsLock)
			.Select(change => {
				return new { 
					ServerItem = change.ServerItem,
					LockLevelName = change.LockLevelName,
					OwnerName = cs.OwnerName,
					ChangeType = change.ChangeType
					};
			})).ToArray();
		}
	
		public static object[] GetOtherFiles(string serverUrl, string serverPath)
		{
		  var uri = new System.Uri(serverUrl);
		  TfsTeamProjectCollection tfs = new TfsTeamProjectCollection(uri);
		  VersionControlServer vcServer = (VersionControlServer)tfs.GetService(typeof(VersionControlServer));

		  // Search for pending sets for all users in all 
		  // workspaces under the passed path.
		  PendingSet[] pendingSets = vcServer.QueryPendingSets(
			  new string[] { serverPath }, 
			  RecursionType.Full, 
			  null, 
			  null);

		  /*System.Console.WriteLine(
			  "Found {0} pending sets under {1}. Searching for Locks...",
			  pendingSets.Length, 
			  serverPath);*/

		  /*foreach (PendingSet changeset in pendingSets)
		  {
			foreach(PendingChange change in changeset.PendingChanges)
			{
			  if (change.IsLock)
			  {
				// We have a lock, display details about it.
				//System.Console.WriteLine("{0} : Locked for {1} by {2}", change.ServerItem, change.LockLevelName, changeset.OwnerName);
			  }
			}
		  }*/
		  
		  return pendingSets.SelectMany(cs => cs.PendingChanges
			.Where(pc => pc.ChangeType != ChangeType.None)
			.Select(change => {
				return new { 
					ServerItem = change.ServerItem,
					LockLevelName = change.LockLevelName,
					OwnerName = cs.OwnerName,
					ChangeType = change.ChangeType
					};
			})).ToArray();
		}
		
		public static object[] GetFilesOwnedBy(string serverUrl, string serverPath, string owner)
		{
		  var uri = new System.Uri(serverUrl);
		  TfsTeamProjectCollection tfs = new TfsTeamProjectCollection(uri);
		  VersionControlServer vcServer = (VersionControlServer)tfs.GetService(typeof(VersionControlServer));

		  // Search for pending sets for all users in all 
		  // workspaces under the passed path.
		  PendingSet[] pendingSets = vcServer.QueryPendingSets(
			  new string[] { serverPath }, 
			  RecursionType.Full, 
			  null, 
			  null);
		  
		  return pendingSets.SelectMany(cs => cs.PendingChanges
			.Where(pc => pc.ChangeType != ChangeType.None & string.Compare(cs.OwnerName, owner, StringComparison.OrdinalIgnoreCase) == 0)
			.Select(change => {
				return new { 
					ServerItem = change.ServerItem,
					LockLevelName = change.LockLevelName,
					OwnerName = cs.OwnerName,
					ChangeType = change.ChangeType
					};
			})).ToArray();
		}		
	}
}
"@

Add-Type -ReferencedAssemblies $tfsReferencedAssemblies -TypeDefinition $source
[TfsTools.LockedFiles]::GetFilesOwnedBy("https://tfsserver/tfs", "$/Genesis/Main","Craig.Wilson")
# [TfsTools.LockedFiles]::GetLockedFiles("https://tfsesrver/tfs", "$/Genesis/Main") #| % { tf lock /lock:none $_.ServerItem }

# tf lock /lock:none $/MyTeamProject/web.config
# tf undo '/workspace:EZE1-DNN-00565;guido.vera' $_.ServerItem 