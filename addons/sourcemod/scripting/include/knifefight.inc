/*
**
*/
#if defined KF_INCLUDE_included
 #endinput
#endif
#define KF_INCLUDE_included

/*
 * Called when a KF Countdown starts
 *
 * @param terrorist            Terrorist index.
 * @param counter-terrorist    Counter-terrorist index.
 * @param timer                Time in secounds till the fight starts.
 * @return Return Plugin_Stop to prevent the countdown.
 */
forward Action KF_OnCountdownStart(int terrorist, int ct, int timer);

/*
 * Called when a KF starts
 *
 * @param terrorist            Terrorist index.
 * @param ct    Counter-terrorist index.
 * @return Return Plugin_Stop to prevent the Fight.
 */
forward Action KF_OnFightStart(int terrorist, int ct);

/*
 * Called when a KF ends
 *
 * @param terrorist            Terrorist index.
 * @param ct    Counter-terrorist index.
 * @param looser               The losser (-1 when it's a draw).
 * @return Return Plugin_Stop to prevent the countdown.
 */
forward void KF_OnFightEnd(int terrorist, int ct, int looser);
